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
    var legacyMetadataHost: String

    public init(loglevel: OSLogType = .default,
                urlSession: URLSession = URLSession(configuration: .default),
                enableOneKey: Bool = false, serverTimeOffset: TimeInterval = 0,
                signerHost: String = "https://signer.tor.us/api/sign",
                allowHost: String = "https://signer.tor.us/api/allow",
                network: TorusNetwork = TorusNetwork.legacy(.MAINNET),
                metadataHost: String = "https://metadata.tor.us",
                clientId: String = "",
                legacyNonce: Bool = false,
                legacyMetadataHost: String = "https://metadata.tor.us"
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
        self.legacyMetadataHost = legacyMetadataHost
    }

    // MARK: - getPublicAddress
    
    public func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel]? = nil, verifier: String, verifierId: String, extendedVerifierId :String? = nil ) async throws -> TorusPublicKey {
        switch network {
        case .legacy(_) :
            guard let torusNodePubs = torusNodePubs else {
                throw fatalError("Torus Node Pub not available")
            }
            return  try await getLegacyPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs , verifier: verifier, verifierId: verifierId, enableOneKey: self.enableOneKey)
        case .sapphire(_) :
            return try await getNewPublicAddress(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId, enableOneKey: self.enableOneKey)
        }
        throw TorusUtilError.runtime("invalid network, \(network)")
    }
    
    
    public func retrieveShares(
        endpoints: [String],
        torusNodePubs : [TorusNodePubModel]? = nil,
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        extraParams: [String:Codable] = [:]
    ) async throws -> TorusKey {
        
//        Support legacy node (api)
        switch network {
        case .legacy(_) :
            guard let torusNodePubs = torusNodePubs else {
                throw fatalError("Torus Node Pub not available")
            }
            
            let result = try await legacyRetrieveShares(torusNodePubs: torusNodePubs, endpoints: endpoints, verifier: verifier, verifierId: verifierParams.verifier_id, idToken: idToken, extraParams: extraParams)
            return result
        case .sapphire(_) :
            
            let result = try await retrieveShare(
                legacyMetadataHost: self.legacyMetadataHost,
                allowHost: self.allowHost,
                enableOneKey: self.enableOneKey,
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
        throw TorusUtilError.runtime("invalid network, \(network)")

    }
    
    
    
    
    public func getUserTypeAndAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel]? = nil, verifier: String, verifierId: String, extendedVerifierId :String? = nil) async throws -> TorusPublicKey {
        switch network {
        case .legacy(_) :
            guard let torusNodePubs = torusNodePubs else {
                throw fatalError("Torus Node Pub not available")
            }
            return try await getLegacyPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, enableOneKey: true)
        case .sapphire(_) :
            return try await getNewPublicAddress(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId, enableOneKey: true)
        }
        throw TorusUtilError.runtime("invalid network, \(network)")
        
        }
    
    
    private func getNewPublicAddress(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId :String? = nil, enableOneKey: Bool) async throws -> TorusPublicKey {
        do {
            
            let result = try await getPubKeyOrKeyAssign(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId );
            let keyResult = result.keyResult;
            let nonceResult = result.nonceResult;
            let nodeIndexes = result.nodeIndexes;
            
            let (X, Y) = ( keyResult.pubKeyX, keyResult.pubKeyY);
            
            if ( nonceResult == nil ) { throw TorusUtilError.runtime("invalid nonce")}
            
            var modifiedPubKey: String
            var oAuthPubKeyString : String
            var pubNonce : PubNonce?
            
            if (extendedVerifierId != nil) {
                modifiedPubKey = "04" + X.addLeading0sForLength64() + Y.addLeading0sForLength64()
                oAuthPubKeyString = modifiedPubKey
            }
            // TODO: implement LegacyNetwork condition
            else {
                modifiedPubKey = "04" + X.addLeading0sForLength64() + Y.addLeading0sForLength64()
                oAuthPubKeyString = modifiedPubKey
                
                let noncePub = "04" + (nonceResult?.pubNonce?.x ?? "0").addLeading0sForLength64() + (nonceResult?.pubNonce?.y ?? "0").addLeading0sForLength64();
                modifiedPubKey =  combinePublicKeys(keys: [modifiedPubKey, noncePub], compressed: false)
                pubNonce = nonceResult?.pubNonce

            }

            let (oAuthX, oAuthY) = try getPublicKeyPointFromAddress(address: oAuthPubKeyString)
            let (finalX, finalY) = try getPublicKeyPointFromAddress(address: modifiedPubKey)
            
            let oAuthAddress = generateAddressFromPubKey(publicKeyX: oAuthX, publicKeyY: oAuthY)
            let finalAddress = generateAddressFromPubKey(publicKeyX: finalX, publicKeyY: finalY)
            
            return .init(
                finalKeyData: .init(
                    evmAddress: finalAddress,
                    X: finalX,
                    Y: finalY
                ),
                oAuthKeyData: .init(
                    evmAddress: oAuthAddress,
                    X: oAuthX,
                    Y: oAuthY
                ),
                metadata: .init(
                    pubNonce: pubNonce,
                    nonce: BigUInt((nonceResult?.nonce)!, radix: 16),
                    typeOfUser: UserType(rawValue: "v2")!,
                    upgraded: nonceResult?.upgraded ?? false
                ),
                nodesData: .init(nodeIndexes: nodeIndexes)
            )
            
        } catch {
            throw error
        }
    }


    

    
    //   Legacy
    private func getLegacyPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, enableOneKey: Bool) async throws -> TorusPublicKey {
        do {
            var data: LegacyKeyLookupResponse
            do {
                data = try await legacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
            } catch {
                if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
                    do {
                        _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network)
                        data = try await awaitLegacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId, timeout: 1)
                    } catch {
                        throw TorusUtilError.configurationError
                    }
                } else {
                    throw error
                }
            }
            let pubKeyX = data.pubKeyX
            let pubKeyY = data.pubKeyY


            let (oAuthX, oAuthY) = (pubKeyX.addLeading0sForLength64(), pubKeyY.addLeading0sForLength64())
            
            var finalPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            var pubNonce: PubNonce?
            var result: TorusPublicKey
            var nonceResult : GetOrSetNonceResult?
            
            if enableOneKey {
                nonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, privateKey: nil, getOnly: !isNewKey)
                pubNonce = nonceResult?.pubNonce
                nonce = BigUInt(nonceResult?.nonce ?? "0") ?? 0

                typeOfUser = .init(rawValue: nonceResult?.typeOfUser ?? ".v1") ?? .v1
                if typeOfUser == .v1 {
                    finalPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    let nonce2 = BigInt(nonce).modulus(modulusValue)
                    if nonce != BigInt(0) {
                        guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                            throw TorusUtilError.decryptionFailed
                        }
                        finalPubKey = combinePublicKeys(keys: [finalPubKey, noncePublicKey.toHexString()], compressed: false)
                    } else {
                        finalPubKey = String(finalPubKey.suffix(128))
                    }
                } else if typeOfUser == .v2 {
                    if nonceResult?.upgraded ?? false {
                        finalPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    } else {
                        guard nonceResult?.pubNonce != nil else { throw TorusUtilError.decodingFailed("No pub nonce found") }
                        finalPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                        let ecpubKeys = "04" + (nonceResult?.pubNonce!.x.addLeading0sForLength64())! + (nonceResult?.pubNonce!.y.addLeading0sForLength64())!
                        finalPubKey = combinePublicKeys(keys: [finalPubKey, ecpubKeys], compressed: false)
                    }
                    finalPubKey = String(finalPubKey.suffix(128))
                } else {
                    throw TorusUtilError.runtime("getOrSetNonce should always return typeOfUser.")
                }
            } else {
                typeOfUser = .v1
                let localNonce = try await getMetadata(dictionary: ["pub_key_X": pubKeyX, "pub_key_Y": pubKeyY])
                nonce = localNonce
                let localPubkeyX = data.pubKeyX
                let localPubkeyY = data.pubKeyY
                finalPubKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
                if localNonce != BigInt(0) {
                    let nonce2 = BigInt(localNonce).modulus(modulusValue)
                    guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                        throw TorusUtilError.decryptionFailed
                    }
                    finalPubKey = combinePublicKeys(keys: [finalPubKey, noncePublicKey.toHexString()], compressed: false)
                } else {
                    finalPubKey = String(finalPubKey.suffix(128))
                }
            }
            let finalX = String(finalPubKey.prefix(64))
            let finalY = String(finalPubKey.suffix(64))

            let oAuthAddress = generateAddressFromPubKey(publicKeyX: oAuthX, publicKeyY: oAuthY)
            let finalAddress = generateAddressFromPubKey(publicKeyX: finalX, publicKeyY: finalY)

            var usertype = ""
            switch typeOfUser{
                case .v1:
                    usertype = "v1"
                case .v2:
                    usertype = "v2"
            }

            result = TorusPublicKey(
                finalKeyData: .init(
                    evmAddress: finalAddress,
                    X: finalX,
                    Y: finalY
                ),
                oAuthKeyData: .init(
                    evmAddress: oAuthAddress,
                    X: oAuthX,
                    Y: oAuthY
                ),
                metadata: .init(
                    pubNonce: pubNonce,
                    nonce: nonce,
                    typeOfUser: UserType(rawValue: usertype)!,
                    upgraded: nonceResult?.upgraded ?? false
                ),
                nodesData: .init(nodeIndexes: [])
            )
            return result
        } catch {
            throw error
        }
    }
    
    private func legacyRetrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey {
            return try await withThrowingTaskGroup(of: TorusKey.self, body: { [unowned self] group in
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

        private func handleRetrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey {
            guard
                let privateKey = generatePrivateKeyData(),
                let publicKey = SECP256K1.privateToPublic(privateKey: privateKey)?.subdata(in: 1 ..< 65)
            else {
                throw TorusUtilError.runtime("Unable to generate SECP256K1 keypair.")
            }

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
                let getPublicAddressData = try await getPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId)
                publicAddress = getPublicAddressData.finalKeyData!.evmAddress
                let localPubkeyX = getPublicAddressData.finalKeyData!.X.addLeading0sForLength64()
                let localPubkeyY = getPublicAddressData.finalKeyData!.Y.addLeading0sForLength64()
                lookupPubkeyX = localPubkeyX
                lookupPubkeyY = localPubkeyY
                let commitmentRequestData = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
                os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, commitmentRequestData)
                
                let (oAuthKeyX, oAuthKeyY, oAuthKey) = try await retrieveDecryptAndReconstruct(endpoints: endpoints, extraParams: extraParams, verifier: verifier, tokenCommitment: idToken, nodeSignatures: commitmentRequestData, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.toHexString())
                
                var metadataNonce: BigUInt
                var typeOfUser: UserType = .v1
                var pubKeyNonceResult: PubNonce?
                var finalPubKey: String = ""

                if enableOneKey {
                    let nonceResult = try await getOrSetNonce(x: oAuthKeyX, y: oAuthKeyY, privateKey: oAuthKey, getOnly: true)
                    metadataNonce = BigUInt(nonceResult.nonce ?? "0", radix: 16) ?? 0
                    typeOfUser = UserType(rawValue: nonceResult.typeOfUser!)!
                    if (typeOfUser == .v2) {
                        finalPubKey = "04" + oAuthKeyX.addLeading0sForLength64() + oAuthKeyY.addLeading0sForLength64()
                        let newkey = "04" + (nonceResult.pubNonce?.x.addLeading0sForLength64())! + (nonceResult.pubNonce?.y.addLeading0sForLength64())!
                        finalPubKey = combinePublicKeys(keys: [finalPubKey, newkey], compressed: false)
                        pubKeyNonceResult = .init(x: nonceResult.pubNonce!.x, y: nonceResult.pubNonce!.y)
                    }
                    

                } else {
                    // for imported keys in legacy networks
                    metadataNonce = try await getMetadata(dictionary: ["pub_key_X": oAuthKeyX, "pub_key_Y": oAuthKeyY])
                    var privateKeyWithNonce = BigInt(metadataNonce) + BigInt(oAuthKey, radix: 16)!
                    privateKeyWithNonce = privateKeyWithNonce.modulus(modulusValue)
                    finalPubKey = (SECP256K1.privateToPublic(privateKey: Data(hex: String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()))?.toHexString())!

                }
                
                let oAuthKeyAddress = generateAddressFromPubKey(publicKeyX: oAuthKeyX, publicKeyY: oAuthKeyY)
                let (finalPubX, finalPubY) = try getPublicKeyPointFromAddress(address: finalPubKey)
                let finalEvmAddress = generateAddressFromPubKey(publicKeyX: finalPubX, publicKeyY: finalPubY)
                
                var finalPrivKey = ""
                if typeOfUser == .v1 || (typeOfUser == .v2 && metadataNonce > BigInt(0)) {
                    let tempNewKey = BigInt(metadataNonce) + BigInt(oAuthKey, radix: 16)!
                    let privateKeyWithNonce = tempNewKey.modulus(modulusValue)
                    finalPrivKey = String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()
                }
                
                var isUpgraded : Bool? = false
                if typeOfUser == .v1 {
                    isUpgraded = nil
                } else if typeOfUser == .v2 {
                    isUpgraded = metadataNonce == BigUInt(0)
                }
                
                return TorusKey(
                    finalKeyData: .init(
                        evmAddress: finalEvmAddress,
                        X: finalPubX,
                        Y: finalPubY,
                        privKey: finalPrivKey
                    ),
                    oAuthKeyData: .init(
                        evmAddress: oAuthKeyAddress,
                        X: oAuthKeyX,
                        Y: oAuthKeyY,
                        privKey: oAuthKey
                    ),
                    sessionData: .init(
                        sessionTokenData: [],
                        sessionAuthKey: ""
                    ),
                    metadata: .init(
                        pubNonce: pubKeyNonceResult,
                        nonce: BigUInt(metadataNonce),
                        typeOfUser: typeOfUser,
                        upgraded: isUpgraded
                    ),
                    nodesData: .init(nodeIndexes: [])
                )
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

        private func retrieveDecryptAndReconstruct(endpoints: [String], extraParams: [String: Codable], verifier: String, tokenCommitment: String, nodeSignatures: [CommitmentRequestResponse], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) async throws -> (String, String, String) {
            // Rebuild extraParams
            let session = createURLSession()
            let threshold = Int(endpoints.count / 2) + 1
            var rpcdata: Data = Data()
            
            let loadedStrings = extraParams
            let valueDict = ["verifieridentifier": verifier,
                             "verifier_id": verifierId,
                             "nodesignatures": nodeSignatures.tostringDict(),
                             "idtoken": tokenCommitment
            ] as [String: Codable]
            let finalItem = loadedStrings.merging(valueDict) { current, _ in current }
            let params =  ["encrypted": "yes",
                        "item": AnyCodable([finalItem])
            ] as [String: AnyCodable]
            
            let dataForRequest = ["jsonrpc": "2.0",
                                  "id": 10,
                                  "method": AnyCodable(JRPC_METHODS.LEGACY_SHARE_REQUEST),
                                  "params": AnyCodable(params)
                                ] as [String: AnyCodable]
            do {
                rpcdata = try JSONEncoder().encode(dataForRequest)
            } catch {
                os_log("import share - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            }
            
//            print("rpc", String(data: rpcdata, encoding: .utf8)!)
            
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
                            
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: _data)
                            if decoded.error != nil {
                                throw TorusUtilError.decodingFailed(decoded.error?.data)
                            }
                            os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")
                            if let decodedResult = decoded.result as? LegacyLookupResponse {
                                print("case non mig")
                                let keyObj = decodedResult.keys
                                if let first = keyObj.first {
                                    let pointHex = PointHex(from: first.publicKey)
                                    shareResponses.append(pointHex)
                                    let metadata = first.metadata
                                    let model = RetrieveDecryptAndReconstuctResponseModel(iv: metadata.iv, ephemPublicKey: metadata.ephemPublicKey, share: first.share, pubKeyX: pointHex.x, pubKeyY: pointHex.y)
                                    resultArray[i] = model
                                }
                            } else if let decodedResult = decoded.result as? LegacyShareRequestResult {
                                print("case mig")
                                let keyObj = decodedResult.keys
                                if let first = keyObj.first {
                                    let pointHex = PointHex(from: .init(x: first.publicKey.X, y: first.publicKey.Y))
                                    shareResponses.append(pointHex)
                                    let metadata = first.metadata
                                    let model = RetrieveDecryptAndReconstuctResponseModel(iv: metadata.iv, ephemPublicKey: metadata.ephemPublicKey, share: first.share, pubKeyX: pointHex.x, pubKeyY: pointHex.y)
                                    resultArray[i] = model
                                }
                            } else {
                                print("decode fail")
                            }
                            
                            // Due to multiple keyAssign

                            let lookupShares = shareResponses.filter { $0 != nil } // Nonnil elements

                            // Comparing dictionaries, so the order of keys doesn't matter
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
