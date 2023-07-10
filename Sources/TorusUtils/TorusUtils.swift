import BigInt
import CryptoKit
import FetchNodeDetails
import CommonSources
/**
 torus utils class
 Author: Shubham Rathi
 */
import Foundation
import OSLog

import secp256k1

@available(macOSApplicationExtension 10.15, *)
var utilsLogType = OSLogType.default

@available(iOS 13, macOS 10.15, *)
open class TorusUtils: AbstractTorusUtils {
    
    
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
    private var timeout: Int = 30
    var urlSession: URLSession
    var serverTimeOffset: TimeInterval = 0
    var isNewKey = false
    var allowHost: String
    var network: TorusNetwork
    var modulusValue = BigInt(CURVE_N, radix: 16)!
    var legacyNonce: Bool
    var metadataHost: String = "https://metadata.tor.us"
    var clientId: String
    var signerHost: String
    var enableOneKey: Bool

    public init(loglevel: OSLogType = .default,
                urlSession: URLSession = URLSession(configuration: .default),
                enableOneKey: Bool = false, serverTimeOffset: TimeInterval = 0,
                signerHost: String = "https://signer.tor.us/api/sign",
                allowHost: String = "https://signer.tor.us/api/allow",
                network: TorusNetwork = TorusNetwork.legacy(.MAINNET),
                metadataHost: String = "https://metadata.tor.us",
                clientId: String = "",
                legacyNonce: Bool = false
    ) {
        self.urlSession = urlSession
        utilsLogType = loglevel
        self.metadataHost = metadataHost
        self.enableOneKey = enableOneKey
        self.signerHost = signerHost
        self.allowHost = allowHost
        self.network = network
        self.serverTimeOffset = serverTimeOffset
        self.legacyNonce = legacyNonce
        self.clientId = clientId
    }

    // MARK: - getPublicAddress
    
    public func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel]? = nil, verifier: String, verifierId: String, extendedVerifierId :String? = nil ) async throws -> String {
        let result = try await getPublicAddressExtended(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId)
        return result.address
    }
    
    public func getPublicAddressExtended(endpoints: [String], torusNodePubs: [TorusNodePubModel]? = nil, verifier: String, verifierId: String, extendedVerifierId :String? = nil ) async throws -> GetPublicAddressResult {
        switch network {
        case .legacy(_) :
            guard let torusNodePubs = torusNodePubs else {
                throw fatalError("Torus Node Pub not available")
            }
            return  try await getLegacyPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs , verifier: verifier, verifierId: verifierId, isExtended: true)
        case .sapphire(_) :
            return try await getNewPublicAddress(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId)
        }
    }


    public func retrieveShares(
        endpoints: [String],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        extraParams: [String:Any] = [:]
    ) async throws -> RetrieveSharesResponse {
        let result = try await retrieveOrImportShare(
            allowHost: self.allowHost,
            network: self.network,
            clientId: self.clientId,
            endpoints: endpoints,
            verifier: verifier,
            verifierParams: verifierParams,
            idToken: idToken,
            extraParams: extraParams
        )
        return result
    }

    

    open func generatePrivateKeyData() -> Data? {
        return Data.randomOfLength(32)
    }

    open func getTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    // TODO: importPrivateKey
    func importPrivateKey(
        endpoints: [String],
        nodeIndexes: [Int],
        nodePubkeys: [INodePub],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        newPrivateKey: String,
        extraParams: [String: Any] = [:]

    ) async throws -> RetrieveSharesResponse {
        
        if endpoints.count != nodeIndexes.count {
            throw TorusUtilError.runtime("Length of endpoints array must be the same as length of nodeIndexes array")
        }
        
        let threshold = endpoints.count / 2 + 1
        let degree = threshold - 1
        var nodeIndexesBigInt: [BigInt] = []
        
        guard let derivedPrivateKeyData = Data(hexString: newPrivateKey) else {
            throw TorusUtilError.privateKeyDeriveFailed
        }
        let key = SECP256K1.privateToPublic(privateKey: derivedPrivateKeyData)
        let privKeyBigInt = BigInt(hex: newPrivateKey) ?? BigInt(0)

        for nodeIndex in nodeIndexes {
            nodeIndexesBigInt.append(BigInt(nodeIndex))
        }
    
        let randomNonce = BigInt(SECP256K1.generatePrivateKey()!)
        
        let oauthKey = privKeyBigInt - randomNonce % modulusValue
        guard let oauthKeyData = Data(hex: String(oauthKey, radix: 16)),
              let oauthPubKey = SECP256K1.privateToPublic(privateKey: oauthKeyData)?.subdata(in: 1 ..< 65).toHexString().padLeft(padChar: "0", count: 128)
        else {
            throw TorusUtilError.runtime("invalid oauth key")
        }
        var pubKeyX = String(oauthPubKey.prefix(64))
        var pubKeyY = String(oauthPubKey.suffix(64))

        let poly = try generateRandomPolynomial(degree: degree, secret: oauthKey)
        let shares = poly.generateShares(shareIndexes: nodeIndexesBigInt)

        let nonceParams = try generateNonceMetadataParams(message: "getOrSetNonce", privateKey: oauthKey, nonce: randomNonce)
        let jsonData = try JSONSerialization.data(withJSONObject: nonceParams.set_data)
        let nonceData = jsonData.base64EncodedString()
        var sharesData: [ImportedShare] = []
        
        var encShares: [Ecies] = []
        var encErrors: [Error] = []
        
        for (i, nodeIndex) in nodeIndexesBigInt.enumerated() {
            let share = shares[String(nodeIndexesBigInt[i], radix: 16).addLeading0sForLength64()]
            let nodePubKey = generateAddressFromPubKey(publicKeyX: nodePubkeys[i].X, publicKeyY: nodePubkeys[i].Y)
            guard let keyData = Data.fromHex(nodePubKey)
            else {
                throw NSError()
            }
            let shareData = share?.share

//            do {
//                // TODO: we need encrypt logic here
//                let key = SymmetricKey(data: keyData)
//                encrypt
//                let iv = AES.GCM.Nonce()
//                let data = try JSONEncoder().encode(shareData);
//                let sealedBox = try AES.GCM.seal(data, using: key, nonce: iv)
//
//
//                let encShareData = encrypt(nodePubKey: nodePubKey, shareData: data)
//                encShares.append(EciesHex(iv: iv.data.hexString(), ephemPublicKey: keyData.hexString(), ciphertext: sealedBox.ciphertext, mac: ))
//                encShares.append(encShareData)
//            } catch {
//                encErrors.append(error)
//            }
            
        }
        
        for (i, nodeIndex) in nodeIndexesBigInt.enumerated() {
            let shareJson = shares[String(nodeIndexesBigInt[i], radix: 16).addLeading0sForLength64()]
            let encParams = encShares[i]
            let encParamsMetadata = encParamsBufToHex(encParams: encParams)
            let shareData = ImportedShare(
                pubKeyX: pubKeyX,
                pubKeyY: pubKeyY,
                encryptedShare: encParamsMetadata.ciphertext!,
                encryptedShareMetadata: encParamsMetadata,
                nodeIndex: Int(shareJson!.shareIndex),
                keyType: "secp256k1",
                nonceData: nonceData,
                nonceSignature: nonceParams.signature
            )
            sharesData.append(shareData)
        }
        
        
        return try await retrieveOrImportShare(
            allowHost: self.allowHost,
            network: self.network,
            clientId: self.clientId,
            endpoints: endpoints,
            verifier: verifier,
            verifierParams: verifierParams,
            idToken: idToken,
            importedShares: sharesData,
            extraParams: extraParams
        )
    }
    
    
    //   Legacy
    public func getLegacyPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressResult {
        print("legacy")
        do {
            var data: KeyLookupResponse
            do {
                data = try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
            } catch {
                if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
                    do {
                        _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network)
                        data = try await awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId, timeout: 1)
                    } catch {
                        throw TorusUtilError.configurationError
                    }
                } else {
                    throw error
                }
            }
            print("dnoe keylookup")
            let pubKeyX = data.pubKeyX
            let pubKeyY = data.pubKeyY
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            var pubNonce: PubNonce?
            let result: GetPublicAddressResult
            if enableOneKey {
                let localNonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, privateKey: nil, getOnly: !isNewKey)
                pubNonce = localNonceResult.pubNonce
                nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
                typeOfUser = .init(rawValue: localNonceResult.typeOfUser ?? ".v1") ?? .v1
                if typeOfUser == .v1 {
                    modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    let nonce2 = BigInt(nonce).modulus(modulusValue)
                    if nonce != BigInt(0) {
                        guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                            throw TorusUtilError.decryptionFailed
                        }
                        modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                    } else {
                        modifiedPubKey = String(modifiedPubKey.suffix(128))
                    }
                } else if typeOfUser == .v2 {
                    if localNonceResult.upgraded ?? false {
                        modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    } else {
                        guard localNonceResult.pubNonce != nil else { throw TorusUtilError.decodingFailed("No pub nonce found") }
                        modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                        let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
                        modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
                    }
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                } else {
                    throw TorusUtilError.runtime("getOrSetNonce should always return typeOfUser.")
                }
                result = .init(address: publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: pubKeyX, y: pubKeyY, metadataNonce: nonce, pubNonce: pubNonce)
            } else {
                typeOfUser = .v1
                let localNonce = try await getMetadata(dictionary: ["pub_key_X": pubKeyX, "pub_key_Y": pubKeyY])
                nonce = localNonce
                let localPubkeyX = data.pubKeyX
                let localPubkeyY = data.pubKeyY
                modifiedPubKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
                if localNonce != BigInt(0) {
                    let nonce2 = BigInt(localNonce).modulus(modulusValue)
                    guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                        throw TorusUtilError.decryptionFailed
                    }
                    modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                } else {
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                }
                result = GetPublicAddressResult(address: publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: localPubkeyX, y: localPubkeyY, metadataNonce: nonce)
            }
            if !isExtended {
                let val = GetPublicAddressResult(address: result.address)
                return val
            } else {
                return result
            }
        } catch {
            throw error
        }
    }
    
    
    public func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool = false) async throws -> GetUserAndAddress {
        do {
            var data: KeyLookupResponse
            do {
                data = try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID)
            } catch {
                if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
                        do {
                            _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePub, verifier: verifier, verifierId: verifierID, signerHost: signerHost, network: network)
                            data = try await awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID, timeout: 1)
                        } catch {
                            throw TorusUtilError.configurationError
                        }
                } else {
                    throw error
                }
            }
            let pubKeyX = data.pubKeyX
            let pubKeyY = data.pubKeyY
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            let localNonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, getOnly: !isNewKey)
            nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
            typeOfUser = TypeOfUser(rawValue: localNonceResult.typeOfUser ?? ".v1") ?? .v1
            if typeOfUser == .v1 {
                modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                let nonce2 = BigInt(nonce).modulus(modulusValue)
                if nonce != BigInt(0) {
                    guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                        throw TorusUtilError.decryptionFailed
                    }
                    modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                } else {
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                }
            } else if typeOfUser == .v2 {
                modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
                modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
                modifiedPubKey = String(modifiedPubKey.suffix(128))

            } else {
                throw TorusUtilError.runtime("getOrSetNonce should always return typeOfUser.")
            }
            let val: GetUserAndAddress = .init(typeOfUser: typeOfUser, address: publicKeyToAddress(key: modifiedPubKey), x: pubKeyX, y: pubKeyY, pubNonce: localNonceResult.pubNonce, nonceResult: localNonceResult.nonce)
            return val
        } catch let error {
           throw error
        }
    }
    
    public func getOrSetNonce(x: String, y: String, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResult {
            var data: Data
            let msg = getOnly ? "getNonce" : "getOrSetNonce"
            do {
                if privateKey != nil {
                    let val = try generateParams(message: msg, privateKey: privateKey!)
                    data = try JSONEncoder().encode(val)
                } else {
                    let dict: [String: Any] = ["pub_key_X": x, "pub_key_Y": y, "set_data": ["data": msg]]
                    data = try JSONSerialization.data(withJSONObject: dict)
                }
                var request = try! makeUrlRequest(url: "\(metadataHost)/get_or_set_nonce")
                request.httpBody = data
                let val = try await urlSession.data(for: request)
                let decoded = try JSONDecoder().decode(GetOrSetNonceResult.self, from: val.0)
                return decoded
            } catch let error {
                throw error
            }
        }
    
    func generateParams(message: String, privateKey: String) throws -> MetadataParams {
        do {
            guard let privKeyData = Data(hex: privateKey),
                  let publicKey = SECP256K1.privateToPublic(privateKey: privKeyData)?.subdata(in: 1 ..< 65).toHexString().padLeft(padChar: "0", count: 128)
            else {
                throw TorusUtilError.runtime("invalid priv key")
            }

            let timeStamp = String(BigUInt(serverTimeOffset + Date().timeIntervalSince1970), radix: 16)
            let setData: MetadataParams.SetData = .init(data: message, timestamp: timeStamp)
            let encodedData = try JSONEncoder().encode(setData)
            guard let sigData = SECP256K1.signForRecovery(hash: encodedData.web3.keccak256, privateKey: privKeyData).serializedSignature else {
                throw TorusUtilError.runtime("sign for recovery hash failed")
            }
            var pubKeyX = String(publicKey.prefix(64))
            var pubKeyY = String(publicKey.suffix(64))
            if !legacyNonce {
             pubKeyX.stripPaddingLeft(padChar: "0")
             pubKeyY.stripPaddingLeft(padChar: "0")
            }
            return .init(pub_key_X: pubKeyX, pub_key_Y: pubKeyY, setData: setData, signature: sigData.base64EncodedString())
        } catch let error {
            throw error
        }
    }
}
