//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 31/05/22.
//

import BigInt
import Crypto
import FetchNodeDetails
import Foundation
import OSLog
import PromiseKit
import secp256k1
import web3

extension TorusUtils {
    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool = false) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()
        let keyLookup = self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID)
        keyLookup.then { lookupData -> Promise<[String: String]> in
            let error = lookupData["err"]

            if error != nil {
                guard let errorString = error else {
                    throw TorusUtilError.runtime("Error not supported")
                }

                // Only assign key in case: Verifier exists and the verifierID doesn't.
                if errorString.contains("Verifier + VerifierID has not yet been assigned") {
                    // Assign key to the user and return (wrapped in a promise)
                    return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePub, verifier: verifier, verifierId: verifierID).then { _ -> Promise<[String: String]> in
                        // Do keylookup again

                        self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID)
                    }.then { data -> Promise<[String: String]> in
                        self.isNewKey = true
                        let error = data["err"]
                        if error != nil {
                            throw TorusUtilError.configurationError
                        }
                        return Promise<[String: String]>.value(data)
                    }
                } else {
                    throw error!
                }

            } else {
                return Promise<[String: String]>.value(lookupData)
            }
        }.done { data in
            guard
                let pubKeyX = data["pub_key_X"],
                let pubKeyY = data["pub_key_Y"]
            else {
                throw TorusUtilError.runtime("pub_key_X and pub_key_Y missing from \(data)")
            }
            var nonceResult: GetOrSetNonceResultModel?
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser = ""
            var pubNonce: GetOrSetNonceResultModel.XY?
            var address: String = ""
            self.getOrSetNonce(x: pubKeyX, y: pubKeyY, getOnly: !self.isNewKey).done { localNonceResult in
                nonceResult = localNonceResult
                nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
                typeOfUser = localNonceResult.typeOfUser
                if typeOfUser == "v1" {
                    let nonce2 = BigInt(nonce).modulus(BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!)
                    if nonce != BigInt(0) {
                        guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                            throw TorusUtilError.decryptionFailed
                        }
                        modifiedPubKey = self.combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                        address = self.publicKeyToAddress(key: modifiedPubKey)
                        seal.fulfill(address)
                    } else {
                        seal.fulfill(data["address"]!)
                    }
                } else if typeOfUser == "v2" {
                    print(self.combinePublicKeys(keys: [pubKeyX, pubKeyY], compressed: false))
                    modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
                    modifiedPubKey = self.combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
                    address = self.publicKeyToAddress(key: modifiedPubKey)
                    seal.fulfill(address)
                } else {
                    seal.reject(TorusUtilError.runtime("getOrSetNonce should always return typeOfUser."))
                }
            }
        }

        return promise
    }
}

extension TorusUtils {
    public func getOrSetNonce(x: String, y: String, privateKey: String? = nil, getOnly: Bool = false) -> Promise<GetOrSetNonceResultModel> {
        let (promise, seal) = Promise<GetOrSetNonceResultModel>.pending()
        var data: Data = Data()
        let msg = getOnly ? "getNonce" : "getOrSetNonce"
        do {
            if privateKey != nil {
                let val = try generateParams(message: msg, privateKey: privateKey!)
                data = try JSONEncoder().encode(val)
            } else {
                let dict: [String: Any] = ["pub_key_X": x, "pub_key_Y": y, "set_data": ["data": msg]]
                data = try JSONSerialization.data(withJSONObject: dict)
            }
            var request = try! makeUrlRequest(url: "https://metadata.tor.us/get_or_set_nonce")
            request.httpBody = data
            urlSession.dataTask(.promise, with: request).done { outputData, _ in
                print(try JSONSerialization.jsonObject(with: outputData))
                let decoded = try JSONDecoder().decode(GetOrSetNonceResultModel.self, from: outputData)
                seal.fulfill(decoded)
            }
            .catch { err in
                seal.reject(err)
            }
        } catch let error {
            seal.reject(error)
        }
        return promise
    }

    func generateParams(message: String, privateKey: String) throws -> MetadataParams {
        do {
            let key = SECP256K1.privateToPublic(privateKey: privateKey.data(using: .utf8) ?? Data()) ?? Data()
            let timeStamp = BigInt(serverTimeOffset + Date().timeIntervalSince1970 / 1000).description
            let setData: MetadataParams.SetData = .init(data: message, timeStamp: timeStamp)
            let encodedData = try JSONEncoder().encode(setData)
            var sig = SECP256K1.signForRecovery(hash: encodedData.sha3(.keccak256), privateKey: key)
            return .init(pub_key_X: "key", pub_key_Y: "", setData: .init(data: "", timeStamp: ""), signature: "")
        } catch let error {
            throw error
        }
    }
}
