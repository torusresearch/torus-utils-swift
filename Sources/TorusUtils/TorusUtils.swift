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
import AnyCodable

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
        torusNodePubs : [TorusNodePubModel]? = nil,
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        extraParams: [String:Codable] = [:]
    ) async throws -> RetrieveSharesResponse {
        
//        Support legacy node (api)
        switch network {
        case .legacy(_) :
            guard let torusNodePubs = torusNodePubs else {
                throw fatalError("Torus Node Pub not available")
            }
            
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
            let result = try await legacyRetrieveShares(torusNodePubs: torusNodePubs, endpoints: endpoints, verifier: verifier, verifierId: verifierParams.verifier_id, idToken: idToken, extraParams: buffer)
            return .init(ethAddress: result.publicAddress, privKey: result.privateKey, sessionTokenData: [], X: "", Y: "", metadataNonce: BigInt(0), postboxPubKeyX: "", postboxPubKeyY: "", sessionAuthKey: "", nodeIndexes: [])
        case .sapphire(_) :
            
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
    
    public func legacyRetrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponseModel {
            return try await withThrowingTaskGroup(of: RetrieveSharesResponseModel.self, body: { [unowned self] group in
                group.addTask { [unowned self] in
                    try await handleRetrieveShares(torusNodePubs: torusNodePubs, endpoints: endpoints, verifier: verifier, verifierId: verifierId, idToken: idToken, extraParams: extraParams)
                }
                group.addTask { [unowned self] in
                    // 60 second timeout for login
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 60_000_000_000))
                    throw TorusUtilError.timeout
                }

                do {
                    for try await val in group {
                        try Task.checkCancellation()
                        group.cancelAll()
                        return val
                    }
                } catch {
                    group.cancelAll()
                    throw error
                }
                throw TorusUtilError.timeout
            })
        }

        func handleRetrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponseModel {
            guard
                let privateKey = generatePrivateKeyData(),
                let publicKey = SECP256K1.privateToPublic(privateKey: privateKey)?.subdata(in: 1 ..< 65)
            else {
                throw TorusUtilError.runtime("Unable to generate SECP256K1 keypair.")
            }
            print("retrieve legacy")

            // Split key in 2 parts, X and Y
            // let publicKeyHex = publicKey.toHexString()
            let pubKeyX = publicKey.prefix(publicKey.count / 2).toHexString().addLeading0sForLength64()
            let pubKeyY = publicKey.suffix(publicKey.count / 2).toHexString().addLeading0sForLength64()

            // Hash the token from OAuth login

            let timestamp = String(Int(getTimestamp()))
            let hashedToken = idToken.sha3(.keccak256)

            var publicAddress: String = ""
            var lookupPubkeyX: String = ""
            var lookupPubkeyY: String = ""
            var pk: String = ""
            do {
                let getPublicAddressData = try await getPublicAddressExtended(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId)
                publicAddress = getPublicAddressData.address
                guard
                    let localPubkeyX = getPublicAddressData.x?.addLeading0sForLength64(),
                    let localPubkeyY = getPublicAddressData.y?.addLeading0sForLength64()
                else { throw TorusUtilError.runtime("Empty pubkey returned from getPublicAddress.") }
                lookupPubkeyX = localPubkeyX
                lookupPubkeyY = localPubkeyY
                let commitmentRequestData = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
                os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, commitmentRequestData)
                let (x, y, key) = try await retrieveDecryptAndReconstruct(endpoints: endpoints, extraParams: extraParams, verifier: verifier, tokenCommitment: idToken, nodeSignatures: commitmentRequestData, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.toHexString())
                if enableOneKey {
                    let result = try await getOrSetNonce(x: x, y: y, privateKey: key, getOnly: true)
                    let nonce = BigUInt(result.nonce ?? "0", radix: 16) ?? 0
                    if nonce != BigInt(0) {
                        let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                        let newKey = tempNewKey.modulus(modulusValue)
                        os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                        pk = BigUInt(newKey).serialize().suffix(64).toHexString()
                    } else {
                        pk = key
                    }
                } else {
                    let nonce = try await getMetadata(dictionary: ["pub_key_X": x, "pub_key_Y": y])
                    if nonce != BigInt(0) {
                        let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                        let newKey = tempNewKey.modulus(modulusValue)
                        os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                        pk = BigUInt(newKey).serialize().suffix(64).toHexString()
                    } else {
                        pk = key
                    }
                }
                return RetrieveSharesResponseModel(publicKey: publicAddress, privateKey: pk)
            } catch {
                os_log("Error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                throw error
            }
        }
    
        open func generatePrivateKeyData() -> Data? {
            return Data.randomOfLength(32)
        }
    
        open func getTimestamp() -> TimeInterval {
            return Date().timeIntervalSince1970
        }
    
    // MARK: - retreiveDecryptAndReconstuct

        func retrieveDecryptAndReconstruct(endpoints: [String], extraParams: Data, verifier: String, tokenCommitment: String, nodeSignatures: [CommitmentRequestResponse], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) async throws -> (String, String, String) {
            // Rebuild extraParams
            let session = createURLSession()
            let threshold = Int(endpoints.count / 2) + 1
            var rpcdata: Data = Data()
            do {
                if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(extraParams) as? [String: Any] {
                    let value = ["verifieridentifier": verifier, "verifier_id": verifierId, "nodesignatures": nodeSignatures.tostringDict(), "idtoken": tokenCommitment] as [String: Any]
                    let keepingCurrent = loadedStrings.merging(value) { current, _ in current }
                    // TODO: Look into hetrogeneous array encoding
                    let dataForRequest = ["jsonrpc": "2.0",
                                          "id": 10,
                                          "method": "ShareRequest",
                                          "params": ["encrypted": "yes",
                                                     "item": [keepingCurrent]] as [String: Any]] as [String: Any]
                    rpcdata = try JSONSerialization.data(withJSONObject: dataForRequest)
                }
            } catch {
                os_log("retrieveDecryptAndReconstruct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            }

            var shareResponses : [PointHex] = []
            var resultArray = [Int: RetrieveDecryptAndReconstuctResponseModel]()
            var errorStack = [Error]()
            var requestArr = [URLRequest]()
            for (_, el) in endpoints.enumerated() {
                do {
                    var rq = try makeUrlRequest(url: el)
                    rq.httpBody = rpcdata
                    requestArr.append(rq)
                } catch {
                    throw error
                }
            }
            return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: {[unowned self] group in
                for (i, rq) in requestArr.enumerated() {
                    group.addTask {
                        do {
                            let val = try await session.data(for: rq)
                            return .success(.init(data: val.0, urlResponse: val.1, index: i))
                        } catch {
                            return .failure(error)
                        }
                    }
                }

                for try await val in group {
                    do {
                        try Task.checkCancellation()
                        switch val {
                        case .success(let model):
                            let _data = model.data
                            let i = model.index
                            print( try JSONSerialization.jsonObject(with: model.data))
                            
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: _data)
                            if decoded.error != nil {
                                throw TorusUtilError.decodingFailed(decoded.error?.data)
                            }
                            os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")

                            guard
                                let decodedResult = decoded.result as? LegacyLookupResponse
                            else { throw TorusUtilError.decodingFailed("keys not found in result \(decoded)") }
                            print("check keys obj")
                            // Due to multiple keyAssign
                            
                            let keyObj = decodedResult.keys
                            if let first = keyObj.first {
//                                guard
//                                    let metadata = first["Metadata"] as? [String: String],
//                                    let share = first["Share"] as? String,
//                                    let publicKey = first["PublicKey"] as? [String: String],
//                                    let iv = metadata["iv"],
//                                    let ephemPublicKey = metadata["ephemPublicKey"],
//                                    let pubKeyX = publicKey["X"],
//                                    let pubKeyY = publicKey["Y"]
//                                else {
//                                    throw TorusUtilError.decodingFailed("\(first)")
//                                }
                                let pointHex = PointHex(from: first.publicKey)
//                                shareResponses[i] = pointHex
                                shareResponses.append(pointHex)
                                let metadata = first.metadata
                                let model = RetrieveDecryptAndReconstuctResponseModel(iv: metadata.iv, ephemPublicKey: metadata.ephemPublicKey, share: first.share, pubKeyX: pointHex.x, pubKeyY: pointHex.y)
                                resultArray[i] = model
                            }
                            print("check for lookupshares")
                            let lookupShares = shareResponses.filter { $0 != nil } // Nonnil elements

                            // Comparing dictionaries, so the order of keys doesn't matter
                            print(lookupShares)
                            let keyResult = thresholdSame(arr: lookupShares.map { $0 }, threshold: threshold) // Check if threshold is satisfied
                            var data: [Int: String] = [:]
                            if keyResult != nil {
                                os_log("retreiveIndividualNodeShares - result: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, resultArray)
                                data = try decryptIndividualShares(shares: resultArray, privateKey: privateKey)
                            } else {
                                throw TorusUtilError.empty
                            }
                            os_log("retrieveDecryptAndReconstuct - data after decryptIndividualShares: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data)
                            let filteredData = data.filter { $0.value != TorusUtilError.decodingFailed(nil).debugDescription }
                            
                            
                            if filteredData.count < threshold { throw TorusUtilError.thresholdError }
                            let thresholdLagrangeInterpolationData = try thresholdLagrangeInterpolation(data: filteredData, endpoints: endpoints, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY)
                            session.invalidateAndCancel()
                            return thresholdLagrangeInterpolationData
                        case .failure(let error):
                            throw error
                        }
                    } catch {
                        errorStack.append(error)
                        let nsErr = error as NSError
                        let userInfo = nsErr.userInfo as [String: Any]
                        if error as? TorusUtilError == .timeout {
                            group.cancelAll()
                            session.invalidateAndCancel()
                            throw error
                        }
                        if nsErr.code == -1003 {
                            // In case node is offline
                            os_log("retrieveDecryptAndReconstuct: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)
                        } else if let err = (error as? TorusUtilError) {
                            if err == TorusUtilError.thresholdError {
                                os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                            }
                        } else {
                            os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                        }
                    }
                }
                throw TorusUtilError.runtime("retrieveDecryptAndReconstuct func failed")
            })

        }


}
