import BigInt
import FetchNodeDetails
import Foundation
import OSLog
import AnyCodable
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

var utilsLogType = OSLogType.default

open class TorusUtils: AbstractTorusUtils {
    private var timeout: Int = 30
    var urlSession: URLSession
    var serverTimeOffset: TimeInterval = 0
    var allowHost: String
    var network: TorusNetwork
    var modulusValue = BigInt(CURVE_N, radix: 16)!
    var clientId: String
    var signerHost: String
    var enableOneKey: Bool
    var legacyMetadataHost: String

    public init(loglevel: OSLogType = .default,
                urlSession: URLSession = URLSession(configuration: .default),
                enableOneKey: Bool = false,
                serverTimeOffset: TimeInterval = 0,
                signerHost: String = "https://signer.tor.us/api/sign",
                allowHost: String = "https://signer.tor.us/api/allow",
                network: TorusNetwork = TorusNetwork.legacy(.MAINNET),
                clientId: String,
                legacyMetadataHost: String = "https://metadata.tor.us"
    ) {
        self.urlSession = urlSession
        utilsLogType = loglevel
        self.enableOneKey = enableOneKey
        self.signerHost = signerHost // TODO: remove signer host read it from fetch node details same as web sdk.
        self.allowHost = allowHost
        self.network = network
        self.serverTimeOffset = serverTimeOffset
        self.clientId = clientId
        self.legacyMetadataHost = legacyMetadataHost
    }

    // MARK: - getPublicAddress

    public func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, extendedVerifierId: String? = nil) async throws -> TorusPublicKey {
        if isLegacyNetwork() {
            return try await getLegacyPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, enableOneKey: enableOneKey)
        } else {
            return try await getNewPublicAddress(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId, enableOneKey: enableOneKey)
        }
    }

    public func retrieveShares(
        endpoints: [String],
        torusNodePubs: [TorusNodePubModel],
        indexes: [BigUInt],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        extraParams: [String: Codable] = [:]
    ) async throws -> TorusKey {
        let session = createURLSession()
        var allowHostRequest = try makeUrlRequest(url: allowHost, httpMethod: .get)
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "origin")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "verifier")
        allowHostRequest.addValue(verifierParams.verifier_id, forHTTPHeaderField: "verifier_id")
        allowHostRequest.addValue(verifierParams.verifier_id, forHTTPHeaderField: "verifierId")
        allowHostRequest.addValue(clientId, forHTTPHeaderField: "clientid")
        allowHostRequest.addValue(network.name, forHTTPHeaderField: "network")
        allowHostRequest.addValue("true", forHTTPHeaderField: "enablegating")
        do {
            let result = try await session.data(for: allowHostRequest)
            let responseData = try JSONDecoder().decode(AllowSuccess.self, from: result.0)
            if (responseData.success == false ) {
                let _ = try JSONDecoder().decode(AllowRejected.self, from: result.0)
                // throw "code: \(errorData.code), error: \(errorData.error)"
            }
        } catch {
            os_log("retrieveShares: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }

        if isLegacyNetwork() {
            let result = try await legacyRetrieveShares(torusNodePubs: torusNodePubs, indexes: indexes, endpoints: endpoints, verifier: verifier, verifierId: verifierParams.verifier_id, idToken: idToken, extraParams: extraParams)
            return result
        } else {
            let result = try await retrieveShare(
                legacyMetadataHost: legacyMetadataHost,
                allowHost: allowHost,
                enableOneKey: enableOneKey,
                network: network,
                clientId: clientId,
                endpoints: endpoints,
                verifier: verifier,
                verifierParams: verifierParams,
                idToken: idToken,
                extraParams: extraParams
            )
            return result
        }
    }

    public func getUserTypeAndAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, extendedVerifierId: String? = nil) async throws -> TorusPublicKey {
        if isLegacyNetwork() {
            return try await getLegacyPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, enableOneKey: true)
        } else {
            return try await getNewPublicAddress(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId, enableOneKey: true)
        }
    }

    private func getNewPublicAddress(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId: String? = nil, enableOneKey: Bool) async throws -> TorusPublicKey {
        do {
            let result = try await getPubKeyOrKeyAssign(endpoints: endpoints, verifier: verifier, verifierId: verifierId, extendedVerifierId: extendedVerifierId)
            let keyResult = result.keyResult
            let nodeIndexes = result.nodeIndexes
            let (X, Y) = (keyResult.pubKeyX, keyResult.pubKeyY)

            let nonceResult = result.nonceResult

            if nonceResult?.pubNonce?.x == nil && extendedVerifierId == nil && !isLegacyNetwork() { throw TorusUtilError.runtime("metadata nonce is missing in share response")
            }

            var modifiedPubKey: String
            var oAuthPubKeyString: String
            var pubNonce: PubNonce?

            if extendedVerifierId != nil {
                modifiedPubKey = (X.addLeading0sForLength64() + Y.addLeading0sForLength64()).add04Prefix()
                oAuthPubKeyString = modifiedPubKey
            } else if isLegacyNetwork() {
                return try await formatLegacyPublicData(finalKeyResult: result.keyResult, enableOneKey: enableOneKey, isNewKey: result.keyResult.isNewKey)
            } else {
                modifiedPubKey = (X.addLeading0sForLength64() + Y.addLeading0sForLength64()).add04Prefix()
                oAuthPubKeyString = modifiedPubKey

                let pubNonceX = (nonceResult?.pubNonce?.x ?? "0")
                let pubNonceY = (nonceResult?.pubNonce?.y ?? "0")
                let noncePub = (pubNonceX.addLeading0sForLength64() + pubNonceY.addLeading0sForLength64()).add04Prefix()
                modifiedPubKey = try combinePublicKeys(keys: [modifiedPubKey, noncePub], compressed: false)
                pubNonce = nonceResult?.pubNonce
            }

            let (oAuthX, oAuthY) = try getPublicKeyPointFromPubkeyString(pubKey: oAuthPubKeyString)
            let (finalX, finalY) = try getPublicKeyPointFromPubkeyString(pubKey: modifiedPubKey)

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
                    nonce: BigUInt(nonceResult?.nonce ?? "0", radix: 16),
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
            var isNewKey = false

            do {
                data = try await legacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
            } catch {
                if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
                    do {
                        _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network)
                        data = try await awaitLegacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId, timeout: 1)
                        isNewKey = true
                    } catch {
                        throw TorusUtilError.configurationError
                    }
                } else {
                    throw error
                }
            }
            let keyLookupData = KeyLookupResponse(pubKeyX: data.pubKeyX, pubKeyY: data.pubKeyY, address: data.address, isNewKey: isNewKey)
            let result = try await formatLegacyPublicData(finalKeyResult: keyLookupData, enableOneKey: enableOneKey, isNewKey: isNewKey)
            return result
        } catch {
            throw error
        }
    }

    private func legacyRetrieveShares(torusNodePubs: [TorusNodePubModel],
                                      indexes: [BigUInt],
                                      endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey {
        return try await withThrowingTaskGroup(of: TorusKey.self, body: { [unowned self] group in
            group.addTask { [unowned self] in
                try await handleRetrieveShares(torusNodePubs: torusNodePubs,
                                               indexes: indexes,
                                               endpoints: endpoints, verifier: verifier, verifierId: verifierId, idToken: idToken, extraParams: extraParams)
            }
            group.addTask { [unowned self] in
                // 60 second timeout for login
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 60000000000))
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

    private func handleRetrieveShares(torusNodePubs: [TorusNodePubModel],
                                      indexes: [BigUInt],
                                      endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey {
        let privateKey = SecretKey()
        let serializedPublicKey = try privateKey.toPublic().serialize(compressed: false)

        // Split key in 2 parts, X and Y
        // let publicKeyHex = publicKey.toHexString()
        let pubKeyX = String(serializedPublicKey.suffix(128).prefix(64))
        let pubKeyY = String(serializedPublicKey.suffix(64))

        // Hash the token from OAuth login

        let timestamp = String(Int(getTimestamp()))

        let hashedToken = keccak256Data(idToken.data(using: .utf8)  ?? Data()).toHexString()
        var lookupPubkeyX: String = ""
        var lookupPubkeyY: String = ""
        do {
            let getPublicAddressData = try await getPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId)
            guard (getPublicAddressData.finalKeyData?.evmAddress) != nil
            else {
                throw TorusUtilError.runtime("Unable to provide evmAddress")
            }
            let localPubkeyX = getPublicAddressData.finalKeyData!.X.addLeading0sForLength64()
            let localPubkeyY = getPublicAddressData.finalKeyData!.Y.addLeading0sForLength64()
            lookupPubkeyX = localPubkeyX
            lookupPubkeyY = localPubkeyY
            let commitmentRequestData = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
            os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, commitmentRequestData)

            let (oAuthKeyX, oAuthKeyY, oAuthKey) = try await retrieveDecryptAndReconstruct(
                endpoints: endpoints,
                indexes: indexes,
                extraParams: extraParams, verifier: verifier, tokenCommitment: idToken, nodeSignatures: commitmentRequestData, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.serialize().addLeading0sForLength64())

            var metadataNonce: BigUInt
            var typeOfUser: UserType = .v1
            var pubKeyNonceResult: PubNonce?
            var finalPubKey: String = ""

            if enableOneKey {
                let nonceResult = try await getOrSetNonce(x: oAuthKeyX, y: oAuthKeyY, privateKey: oAuthKey, getOnly: true)
                metadataNonce = BigUInt(nonceResult.nonce ?? "0", radix: 16) ?? 0
                let nonceType = nonceResult.typeOfUser ?? "v1"
                typeOfUser = UserType(rawValue: nonceType) ?? UserType.v1
                if typeOfUser == .v2 {
                    finalPubKey = (oAuthKeyX.addLeading0sForLength64() + oAuthKeyY.addLeading0sForLength64()).add04Prefix()
                    let newkey = ((nonceResult.pubNonce?.x.addLeading0sForLength64())! + (nonceResult.pubNonce?.y.addLeading0sForLength64())!).add04Prefix()
                    finalPubKey = try combinePublicKeys(keys: [finalPubKey, newkey], compressed: false)
                    pubKeyNonceResult = .init(x: nonceResult.pubNonce!.x, y: nonceResult.pubNonce!.y)
                } else {
                    // for imported keys in legacy networks
                    metadataNonce = try await getMetadata(dictionary: ["pub_key_X": oAuthKeyX, "pub_key_Y": oAuthKeyY])
                    var privateKeyWithNonce = BigInt(metadataNonce) + BigInt(oAuthKey, radix: 16)!
                    privateKeyWithNonce = privateKeyWithNonce.modulus(modulusValue)
                    let serializedKey =  privateKeyWithNonce.magnitude.serialize().hexString.addLeading0sForLength64()
                    let finalPrivateKey = try
                    SecretKey(hex: serializedKey)
                    finalPubKey = try finalPrivateKey.toPublic().serialize(compressed: false)
                }
            } else {
                // for imported keys in legacy networks
                metadataNonce = try await getMetadata(dictionary: ["pub_key_X": oAuthKeyX, "pub_key_Y": oAuthKeyY])
                var privateKeyWithNonce = BigInt(metadataNonce) + BigInt(oAuthKey, radix: 16)!
                privateKeyWithNonce = privateKeyWithNonce.modulus(modulusValue)
                let finalPrivateKey = try SecretKey(hex: privateKeyWithNonce.magnitude.serialize().hexString.addLeading0sForLength64())
                finalPubKey = try finalPrivateKey.toPublic().serialize(compressed: false)
            }

            let oAuthKeyAddress = generateAddressFromPubKey(publicKeyX: oAuthKeyX, publicKeyY: oAuthKeyY)
            let (finalPubX, finalPubY) = try getPublicKeyPointFromPubkeyString(pubKey: finalPubKey)
            let finalEvmAddress = generateAddressFromPubKey(publicKeyX: finalPubX, publicKeyY: finalPubY)

            var finalPrivKey = ""
            if typeOfUser == .v1 || (typeOfUser == .v2 && metadataNonce > BigInt(0)) {
                let tempNewKey = BigInt(metadataNonce) + BigInt(oAuthKey, radix: 16)!
                let privateKeyWithNonce = tempNewKey.modulus(modulusValue)
                finalPrivKey = String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()
            }

            var isUpgraded: Bool? = false
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

    open func getTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }

    // MARK: - retreiveDecryptAndReconstuct

    private func retrieveDecryptAndReconstruct(endpoints: [String],
                                               indexes: [BigUInt],
                                               extraParams: [String: Codable], verifier: String, tokenCommitment: String, nodeSignatures: [CommitmentRequestResponse], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) async throws -> (String, String, String) {
        // Rebuild extraParams
        let session = createURLSession()
        let threshold = Int(endpoints.count / 2) + 1
        var rpcdata: Data = Data()

        let loadedStrings = extraParams
        let valueDict = ["verifieridentifier": verifier,
                         "verifier_id": verifierId,
                         "nodesignatures": nodeSignatures.tostringDict(),
                         "idtoken": tokenCommitment,
        ] as [String: Codable]
        let finalItem = loadedStrings.merging(valueDict) { current, _ in current }
        let params = ["encrypted": "yes",
                      "item": AnyCodable([finalItem]),
        ] as [String: AnyCodable]

        let dataForRequest = ["jsonrpc": "2.0",
                              "id": 10,
                              "method": AnyCodable(JRPC_METHODS.LEGACY_SHARE_REQUEST),
                              "params": AnyCodable(params),
        ] as [String: AnyCodable]
        do {
            rpcdata = try JSONEncoder().encode(dataForRequest)
        } catch {
            os_log("import share - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }

        var shareResponses: [PointHex?] = []
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
        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { [unowned self] group in
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
                    case let .success(model):
                        let _data = model.data
                        let i = Int(indexes[model.index]) - 1

                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: _data)

                        if decoded.error != nil {
                            throw TorusUtilError.decodingFailed(decoded.error?.data)
                        }
                        os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")
                        var X = lookupPubkeyX.addLeading0sForLength64()
                        var Y = lookupPubkeyY.addLeading0sForLength64()
                        if let decodedResult = decoded.result as? LegacyLookupResponse {
                            // case non migration
                            let keyObj = decodedResult.keys
                            if let first = keyObj.first {
                                let pointHex = PointHex(from: first.publicKey)
                                shareResponses.append(pointHex)
                                let metadata = first.metadata
                                let model = RetrieveDecryptAndReconstuctResponseModel(iv: metadata.iv, ephemPublicKey: metadata.ephemPublicKey, share: first.share, pubKeyX: pointHex.x, pubKeyY: pointHex.y, mac: metadata.mac)
                                resultArray[i] = model
                            }
                        } else if let decodedResult = decoded.result as? LegacyShareRequestResult {
                            // case migration
                            let keyObj = decodedResult.keys
                            if let first = keyObj.first {
                                let pointHex = PointHex(from: .init(x: first.publicKey.X, y: first.publicKey.Y))
                                shareResponses.append(pointHex)
                                let metadata = first.metadata
                                X = pointHex.x
                                Y = pointHex.y
                                let model = RetrieveDecryptAndReconstuctResponseModel(iv: metadata.iv, ephemPublicKey: metadata.ephemPublicKey, share: first.share, pubKeyX: pointHex.x, pubKeyY: pointHex.y, mac: metadata.mac)
                                resultArray[i] = model
                            }
                        } else {
                            throw TorusUtilError.runtime("decode fail")
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
                        let thresholdLagrangeInterpolationData = try thresholdLagrangeInterpolation(data: filteredData, endpoints: endpoints, lookupPubkeyX: X.addLeading0sForLength64(), lookupPubkeyY: Y.addLeading0sForLength64())
                        session.invalidateAndCancel()
                        return thresholdLagrangeInterpolationData
                    case let .failure(error):
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
