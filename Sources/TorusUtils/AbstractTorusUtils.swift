//
//  File.swift
//
//
//  Created by Shubham on 1/8/21.
//

import BigInt
import FetchNodeDetails
import Foundation
import PromiseKit

public protocol AbstractTorusUtils {
    func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePubModel>)

    func retrieveShares(endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String: String]>

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool)  -> Promise<[String: String]>
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
            urlSession.dataTask(.promise, with: request).done { outputData,response in
                print( try JSONSerialization.jsonObject(with: outputData))
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
        } catch(let error) {
            throw error
        }
    }
}

public struct GetOrSetNonceResultModel: Decodable {

    var typeOfUser: String
    var nonce: String?
    var pubNonce: XY?
    var ifps: String?
    var upgraded: Bool?

    struct XY: Decodable {
        var x: String
        var y: String
    }
}

public struct V1UserTypeAndAddress {
    var typeOfUser: String
    var nonce: BigInt?
    var x: String
    var y: String
    var address: String
}

public struct MetadataParams: Codable {
    struct SetData: Codable {
        var data: String
        var timeStamp: String
    }

    var namespace: String?
    var pub_key_X: String
    var pub_key_Y: String
    var setData: SetData
    var signature: String
}

public struct V2UserTypeAndAddress {
    var typeOfUser: String
    var nonce: BigInt?
    var pubNonce: TorusNodePubModel
    var ifps: String?
    var upgraded: Bool?
    var x: String
    var y: String
    var address: String
}
