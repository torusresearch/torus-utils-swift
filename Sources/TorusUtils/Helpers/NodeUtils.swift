import BigInt
import FetchNodeDetails
import Foundation
import OSLog
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

internal class NodeUtils {
    public static func getPubKeyOrKeyAssign(
        endpoints: [String],
        network: TorusNetwork,
        verifier: String,
        verifierId: String,
        legacyMetadataHost: String,
        serverTimeOffset: Int? = nil,
        extendedVerifierId: String? = nil) async throws -> KeyLookupResult {
        let threshold = Int(trunc(Double((endpoints.count / 2) + 1)))

        let params = GetOrSetKeyParams(distributed_metadata: true, verifier: verifier, verifier_id: verifierId, extended_verifier_id: extendedVerifierId, one_key_flow: true, fetch_node_index: true, client_time: String(Int(trunc(Double((serverTimeOffset ?? 0) + Int(Date().timeIntervalSince1970))))))
        let jsonRPCRequest = JRPCRequest(
            method: JRPC_METHODS.GET_OR_SET_KEY,
            params: params
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let rpcdata = try encoder.encode(jsonRPCRequest)

        var nonceResult: GetOrSetNonceResult?
        var nodeIndexes: [Int] = []

        let minRequired = Int(trunc(Double(endpoints.count * 3 / 4) + 1))

        let lookupResults: [JRPCResponse<VerifierLookupResponse>?] = try await withThrowingTaskGroup(of: JRPCResponse?.self, returning: [JRPCResponse<VerifierLookupResponse>?].self) { group -> [JRPCResponse?] in
            var received: Int = 0
            for endpoint in endpoints {
                group.addTask {
                    do {
                        var request = try MetadataUtils.makeUrlRequest(url: endpoint)
                        request.httpBody = rpcdata
                        let val = try await URLSession(configuration: .default).data(for: request)
                        let decoded = try JSONDecoder().decode(JRPCResponse<VerifierLookupResponse>.self, from: val.0)
                        return decoded
                    } catch {
                        return nil
                    }
                }
            }
            var collected = [JRPCResponse<VerifierLookupResponse>?]()
            for try await value in group {
                collected.append(value)
                if value != nil && value?.error == nil {
                    received += 1
                    if received >= minRequired {
                        group.cancelAll()
                    }
                }
            }
            return collected
        }

        let lookupPubKeys = lookupResults.filter({ $0 != nil && $0?.error == nil })

        let errorResult = try thresholdSame(arr: lookupResults.filter({ $0?.error != nil }).map { $0?.error }, threshold: threshold)

        let normalizedKeyResults = lookupPubKeys.map({ normalizeKeysResult(result: ($0!.result)!) })

        let keyResult = try thresholdSame(arr: normalizedKeyResults, threshold: threshold)

        if keyResult != nil && nonceResult == nil && extendedVerifierId == nil && !TorusUtils.isLegacyNetworkRouteMap(network: network) {
            for i in 0 ..< lookupResults.count {
                let x1 = lookupResults[i]
                if x1 != nil && x1?.error == nil {
                    let currentNodePubKeyX = x1!.result!.keys[0].pub_key_X.addLeading0sForLength64().lowercased()
                    let thresholdPubKeyX = keyResult!.keys[0].pub_key_X.addLeading0sForLength64().lowercased()
                    let pubNonce: PubNonce? = x1!.result!.keys[0].nonce_data?.pubNonce
                    if pubNonce != nil && currentNodePubKeyX == thresholdPubKeyX {
                        nonceResult = x1?.result?.keys[0].nonce_data
                        break
                    }
                }
            }

            if nonceResult == nil {
                let metadataNonce = try await MetadataUtils.getOrSetSapphireMetadataNonce(legacyMetadataHost: legacyMetadataHost, network: network, X: keyResult!.keys[0].pub_key_X, Y: keyResult!.keys[0].pub_key_Y)
                nonceResult = metadataNonce
            }
        }

        var serverTimeOffsets: [Int] = []
        if keyResult != nil && (nonceResult != nil || extendedVerifierId != nil || TorusUtils.isLegacyNetworkRouteMap(network: network) || errorResult != nil) {
            for i in 0 ..< lookupResults.count {
                let x1 = lookupResults[i]
                if x1 != nil && x1?.result != nil {
                    let currentNodePubKey = x1!.result!.keys[0].pub_key_X.lowercased()
                    let thresholdPubKey = keyResult!.keys[0].pub_key_X.lowercased()
                    if currentNodePubKey == thresholdPubKey {
                        let nodeIndex = Int(x1!.result!.node_index)
                        if nodeIndex != nil {
                            nodeIndexes.append(nodeIndex!)
                        }
                    }
                    let serverTimeOffset: Int = Int(x1!.result!.server_time_offset ?? "0")!
                    serverTimeOffsets.append(serverTimeOffset)
                }
            }
        }

        let serverTimeOffset = (keyResult != nil) ? calculateMedian(arr: serverTimeOffsets) : 0

        return KeyLookupResult(
            keyResult: keyResult,
            nodeIndexes: nodeIndexes,
            serverTimeOffset: serverTimeOffset,
            nonceResult: nonceResult,
            errorResult: errorResult == nil ? nil : errorResult as? ErrorMessage)
    }

    public static func retrieveOrImportShare(
        legacyMetadataHost: String,
        serverTimeOffset: Int?,
        enableOneKey: Bool,
        allowHost: String,
        network: TorusNetwork,
        clientId: String,
        endpoints: [String],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        importedShares: [ImportedShare]?,
        apiKey: String = "torus-default",
        extraParams: [String: Codable] = [:]
    ) async throws -> TorusKey {
        let threshold = Int(trunc(Double((endpoints.count / 2) + 1)))

        var allowHostRequest = try MetadataUtils.makeUrlRequest(url: allowHost, httpMethod: .get)
        allowHostRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "origin")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "verifier")
        allowHostRequest.addValue(verifierParams.verifier_id, forHTTPHeaderField: "verifierid")
        allowHostRequest.addValue(network.name, forHTTPHeaderField: "network")
        allowHostRequest.addValue(clientId, forHTTPHeaderField: "clientid")
        allowHostRequest.addValue("true", forHTTPHeaderField: "enablegating")
        let allowHostResult = try await URLSession(configuration: .default).data(for: allowHostRequest)
        let allowHostResultData = try JSONDecoder().decode(AllowSuccess.self, from: allowHostResult.0)
        if allowHostResultData.success == false {
            let errorData = try JSONDecoder().decode(AllowRejected.self, from: allowHostResult.0)
            throw TorusUtilError.gatingError("code: \(errorData.code), error: \(errorData.error)")
        }

        let sessionAuthKey = SecretKey()
        let sessionAuthKeySerialized = try sessionAuthKey.serialize().addLeading0sForLength64()
        let pubKey = try sessionAuthKey.toPublic().serialize(compressed: false)
        let (pubX, pubY) = try KeyUtils.getPublicKeyCoords(pubKey: pubKey)
        let tokenCommitment = try KeyUtils.keccak256Data(idToken)

        var isImportShareReq = false
        var importedShareCount = 0
        if importedShares != nil && importedShares!.count > 0 {
            if importedShares!.count != endpoints.count {
                throw TorusUtilError.importShareFailed
            }
            isImportShareReq = true
            importedShareCount = importedShares!.count
        }

        let params = CommitmentRequestParams(messageprefix: "mug00", tokencommitment: tokenCommitment, temppubx: pubX, temppuby: pubY, verifieridentifier: verifier, timestamp: String(BigUInt(trunc(Double((serverTimeOffset ?? 0) + Int(Date().timeIntervalSince1970)))), radix: 16))

        let jsonRPCRequest = JRPCRequest(
            method: JRPC_METHODS.COMMITMENT_REQUEST,
            params: params
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let rpcdata = try encoder.encode(jsonRPCRequest)

        let minRequired = Int(trunc(Double(endpoints.count * 3 / 4) + 1))

        let commitmentRequestResults: [JRPCResponse<CommitmentRequestResult>?] = try await withThrowingTaskGroup(of: JRPCResponse?.self, returning: [JRPCResponse<CommitmentRequestResult>?].self) { group -> [JRPCResponse?] in
            var received: Int = 0
            for endpoint in endpoints {
                group.addTask {
                    do {
                        var request = try MetadataUtils.makeUrlRequest(url: endpoint)
                        request.httpBody = rpcdata
                        let val = try await URLSession(configuration: .default).data(for: request)
                        let decoded = try JSONDecoder().decode(JRPCResponse<CommitmentRequestResult>.self, from: val.0)
                        return decoded
                    } catch {
                        return nil
                    }
                }
            }
            var collected = [JRPCResponse<CommitmentRequestResult>?]()
            for try await value in group {
                collected.append(value)
                if !isImportShareReq && value != nil && value?.error == nil {
                    received += 1
                    if received >= minRequired {
                        group.cancelAll()
                    }
                } else if isImportShareReq {
                    if value == nil || value?.error != nil {
                        // cannot continue, all must pass for import
                        group.cancelAll()
                    }
                }
            }
            return collected
        }

        let completedCommitmentRequests = commitmentRequestResults.filter({ $0 != nil && $0?.error == nil })

        if importedShareCount > 0 && !(commitmentRequestResults.count == endpoints.count) {
            throw TorusUtilError.commitmentRequestFailed
        }

        let nodeSigs = completedCommitmentRequests.filter({ $0?.error == nil }).map({ $0!.result })

        var thresholdNonceData: GetOrSetNonceResult?

        let sessionExpiry: Int? = extraParams["session_token_exp_second"] as? Int

        var shareImportSuccess = false

        var shareRequestResults: [ShareRequestResult?] = []

        if isImportShareReq {
            var importedItems: [ShareRequestParams.ShareRequestItem] = []
            for j in 0 ..< endpoints.count {
                let importShare = importedShares![j]

                let shareRequestItem = ShareRequestParams.ShareRequestItem(
                    verifieridentifier: verifier,
                    verifier_id: verifierParams.verifier_id,
                    extended_verifier_id: verifierParams.extended_verifier_id,
                    idtoken: idToken,
                    nodesignatures: nodeSigs,
                    pub_key_x: importShare.oauth_pub_key_x,
                    pub_key_y: importShare.oauth_pub_key_y,
                    signing_pub_key_x: importShare.signing_pub_key_x,
                    signing_pub_key_y: importShare.signing_pub_key_y,
                    encrypted_share: importShare.encryptedShare,
                    encrypted_share_metadata: importShare.encryptedShareMetadata,
                    node_index: importShare.node_index,
                    key_type: importShare.key_type,
                    nonce_data: importShare.nonce_data,
                    nonce_signature: importShare.nonce_signature,
                    // extra_params: extraData
                    sub_verifier_ids: verifierParams.sub_verifier_ids,
                    session_token_exp_second: sessionExpiry,
                    verify_params: verifierParams.verify_params,
                    sss_endpoint: endpoints[j]
                )

                importedItems.append(shareRequestItem)
            }

            let params = ShareRequestParams(encrypted: "yes", item: importedItems, client_time: String(Int(trunc(Double((serverTimeOffset ?? 0) + Int(Date().timeIntervalSince1970))))))

            let jsonRPCRequest = JRPCRequest(
                method: JRPC_METHODS.IMPORT_SHARES,
                params: params
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let rpcdata = try encoder.encode(jsonRPCRequest)
            var request = try MetadataUtils.makeUrlRequest(url: endpoints[Int(try getProxyCoordinatorEndpointIndex(endpoints: endpoints, verifier: verifier, verifierId: verifierParams.verifier_id))])
            request.httpBody = rpcdata
            let val = try await URLSession(configuration: .default).data(for: request)
            let decoded = try JSONDecoder().decode(JRPCResponse<[ShareRequestResult]>.self, from: val.0)
            if decoded.error == nil {
                shareImportSuccess = true
            }

            if isImportShareReq && !shareImportSuccess {
                throw TorusUtilError.importShareFailed
            }

            shareRequestResults = decoded.result!

        } else {
            let shareResults: [JRPCResponse<ShareRequestResult>?] = try await withThrowingTaskGroup(of: JRPCResponse?.self, returning: [JRPCResponse<ShareRequestResult>?].self) {
                group -> [JRPCResponse<ShareRequestResult>?] in
                var received = 0

                for i in 0 ..< endpoints.count {
                    if !nodeSigs.indices.contains(i) {
                        if isImportShareReq {
                            throw TorusUtilError.importShareFailed
                        }
                        continue
                    }

                    group.addTask {
                        do {
                            let shareRequestItem = ShareRequestParams.ShareRequestItem(
                                verifieridentifier: verifier,
                                verifier_id: verifierParams.verifier_id,
                                extended_verifier_id: verifierParams.extended_verifier_id,
                                idtoken: idToken,
                                nodesignatures: nodeSigs,
                                // extra_params: extraData
                                sub_verifier_ids: verifierParams.sub_verifier_ids,
                                session_token_exp_second: sessionExpiry,
                                verify_params: verifierParams.verify_params
                            )

                            let params = ShareRequestParams(encrypted: "yes", item: [shareRequestItem], client_time: String(Int(trunc(Double((serverTimeOffset ?? 0) + Int(Date().timeIntervalSince1970))))))

                            let jsonRPCRequest = JRPCRequest(
                                method: JRPC_METHODS.GET_SHARE_OR_KEY_ASSIGN,
                                params: params
                            )

                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .sortedKeys
                            let rpcdata = try encoder.encode(jsonRPCRequest)
                            var request = try MetadataUtils.makeUrlRequest(url: endpoints[i])
                            request.httpBody = rpcdata
                            let val = try await URLSession(configuration: .default).data(for: request)
                            let decoded = try JSONDecoder().decode(JRPCResponse<ShareRequestResult>.self, from: val.0)
                            return decoded
                        } catch {
                            return nil
                        }
                    }
                }

                var collected = [JRPCResponse<ShareRequestResult>?]()
                for try await value in group {
                    collected.append(value)
                    if !isImportShareReq {
                        if value != nil && value?.error == nil {
                            received += 1
                            if received >= minRequired {
                                group.cancelAll()
                            }
                        }
                    }
                }

                return collected
            }
            shareRequestResults = shareResults.map({ $0?.result })
        }

        let shareResponses: [ShareRequestResult] = shareRequestResults.filter({ $0 != nil }).map({ $0! })

        let pubkeys = shareResponses.filter({ $0.keys.count > 0 }).map { $0.keys[0].publicKey }

        let thresholdPublicKey = try thresholdSame(arr: pubkeys, threshold: threshold)

        if thresholdPublicKey == nil {
            throw TorusUtilError.retrieveOrImportShareError
        }

        for item in shareResponses {
            if thresholdNonceData == nil && verifierParams.extended_verifier_id == nil {
                let currentPubKeyX = item.keys[0].publicKey.X.addLeading0sForLength64().lowercased()
                let thesholdPubKeyX = thresholdPublicKey!.X.addLeading0sForLength64().lowercased()
                let pubNonce: PubNonce? = item.keys[0].nonceData?.pubNonce
                if pubNonce != nil && currentPubKeyX == thesholdPubKeyX {
                    thresholdNonceData = item.keys[0].nonceData
                }
            }
        }

        var serverTimeOffsets: [String] = []
        for item in shareResponses {
            serverTimeOffsets.append(item.serverTimeOffset)
        }
        let serverOffsetTimes = serverTimeOffsets.map({ Int($0) ?? 0 })

        let serverTimeOffsetResponse: Int = serverTimeOffset ?? calculateMedian(arr: serverOffsetTimes)

        if thresholdNonceData == nil && verifierParams.extended_verifier_id == nil && !TorusUtils.isLegacyNetworkRouteMap(network: network) {
            let metadataNonce = try await MetadataUtils.getOrSetSapphireMetadataNonce(legacyMetadataHost: legacyMetadataHost, network: network, X: thresholdPublicKey!.X, Y: thresholdPublicKey!.Y, serverTimeOffset: serverTimeOffsetResponse, getOnly: false)
            thresholdNonceData = metadataNonce
            if thresholdNonceData != nil {
                if thresholdNonceData!.nonce != nil {
                    thresholdNonceData!.nonce = nil
                }
            }
        }

        let thresholdReqCount = (importedShares != nil && importedShares!.count > 0) ? endpoints.count : threshold

        // Invert comparision to return error early
        if !(shareResponses.count >= thresholdReqCount && thresholdPublicKey != nil && (thresholdNonceData != nil || verifierParams.extended_verifier_id != nil || TorusUtils.isLegacyNetworkRouteMap(network: network))) {
            throw TorusUtilError.retrieveOrImportShareError
        }

        var shares: [String?] = []
        var sessionTokenSigs: [String?] = []
        var sessionTokens: [String?] = []
        var nodeIndexes: [Int?] = []
        var sessionTokenDatas: [SessionToken?] = []
        var isNewKeys: [String] = []

        for item in shareResponses {
            isNewKeys.append(item.isNewKey)

            if !item.sessionTokenSigs.isEmpty {
                if !item.sessionTokenSigMetadata.isEmpty {
                    let decrypted = try MetadataUtils.decryptNodeData(eciesData: item.sessionTokenSigMetadata[0], ciphertextHex: item.sessionTokenSigs[0], privKey: sessionAuthKeySerialized)
                    sessionTokenSigs.append(decrypted)
                } else {
                    sessionTokenSigs.append(item.sessionTokenSigs[0])
                }
            } else {
                sessionTokenSigs.append(nil)
            }

            if !item.sessionTokens.isEmpty {
                if !item.sessionTokenMetadata.isEmpty {
                    let decrypted = try MetadataUtils.decryptNodeData(eciesData: item.sessionTokenMetadata[0], ciphertextHex: item.sessionTokens[0], privKey: sessionAuthKeySerialized)
                    sessionTokens.append(decrypted)
                } else {
                    sessionTokens.append(item.sessionTokens[0])
                }
            } else {
                sessionTokens.append(nil)
            }

            if !item.keys.isEmpty {
                let latestKey = item.keys[0]
                nodeIndexes.append(latestKey.nodeIndex)
                guard let cipherData = Data(base64Encoded: latestKey.share) else {
                    throw TorusUtilError.decodingFailed("cipher is not base64 encoded")
                }
                guard let cipherTextHex = String(data: cipherData, encoding: .utf8) else {
                    throw TorusUtilError.decodingFailed("cipherData is not utf8")
                }
                let decrypted = try MetadataUtils.decryptNodeData(eciesData: latestKey.shareMetadata, ciphertextHex: cipherTextHex, privKey: sessionAuthKeySerialized)
                shares.append(decrypted)
            } else {
                nodeIndexes.append(nil)
                shares.append(nil)
            }
        }

        let validSigs = sessionTokenSigs.filter({ $0 != nil }).map({ $0! })

        if verifierParams.extended_verifier_id == nil && validSigs.count < threshold {
            throw TorusUtilError.retrieveOrImportShareError
        }

        let validTokens = sessionTokens.filter({ $0 != nil }).map({ $0! })

        if verifierParams.extended_verifier_id == nil && validTokens.count < threshold {
            throw TorusUtilError.runtime("Insufficient number of signatures from nodes")
        }

        for (i, item) in sessionTokens.enumerated() {
            if item == nil {
                sessionTokenDatas.append(nil)
            } else {
                sessionTokenDatas.append(SessionToken(token: item!.data(using: .utf8)!.base64EncodedString(), signature: sessionTokenSigs[i]!.data(using: .utf8)!.hexString, node_pubx: shareResponses[i].nodePubX, node_puby: shareResponses[i].nodePubY))
            }
        }

        var decryptedShares: [Int: String] = [:]
        for (i, item) in shares.enumerated() {
            if item != nil {
                decryptedShares.updateValue(item!, forKey: nodeIndexes[i]!)
            }
        }
        let elements = Array(0 ... decryptedShares.keys.max()!) // Note: torus.js has a bug that this line resolves

        let allCombis = kCombinations(elements: elements.slice, k: threshold)

        var privateKey: String?

        for j in 0 ..< allCombis.count {
            let currentCombi = allCombis[j]
            let currentCombiShares = decryptedShares.filter({ currentCombi.contains($0.key) })
            let shares = currentCombiShares.map({ $0.value })
            let indices = currentCombiShares.map({ $0.key })
            let derivedPrivateKey = try? Lagrange.lagrangeInterpolation(shares: shares, nodeIndex: indices)
            if derivedPrivateKey == nil {
                continue
            }
            let decryptedPubKey = try SecretKey(hex: derivedPrivateKey!).toPublic().serialize(compressed: false)
            let (decryptedPubKeyX, decryptedPubKeyY) = try KeyUtils.getPublicKeyCoords(pubKey: decryptedPubKey)
            let thresholdPubKeyX = thresholdPublicKey!.X.addLeading0sForLength64().lowercased()
            let thresholdPubKeyY = thresholdPublicKey!.Y.addLeading0sForLength64().lowercased()
            if decryptedPubKeyX.lowercased() == thresholdPubKeyX && decryptedPubKeyY.lowercased() == thresholdPubKeyY {
                privateKey = derivedPrivateKey
                break
            }
        }

        if privateKey == nil {
            throw TorusUtilError.privateKeyDeriveFailed
        }

        let thresholdIsNewKey: String? = try thresholdSame(arr: isNewKeys, threshold: threshold)

        let oAuthKey = privateKey!
        let oAuthPublicKey = try SecretKey(hex: oAuthKey).toPublic().serialize(compressed: false)
        let (oAuthPublicKeyX, oAuthPublicKeyY) = try KeyUtils.getPublicKeyCoords(pubKey: oAuthPublicKey)
        var metadataNonce = BigInt(thresholdNonceData?.nonce?.addLeading0sForLength64() ?? "0", radix: 16) ?? BigInt(0)
        var finalPubKey: String?
        var pubNonce: PubNonce?
        var typeOfUser: UserType = .v1
        if verifierParams.extended_verifier_id != nil {
            typeOfUser = .v2
            finalPubKey = oAuthPublicKey
        } else if TorusUtils.isLegacyNetworkRouteMap(network: network) {
            if enableOneKey {
                let isNewKey = !(thresholdIsNewKey == "true")
                let nonce = try await MetadataUtils.getOrSetNonce(legacyMetadataHost: legacyMetadataHost, serverTimeOffset: serverTimeOffsetResponse, X: oAuthPublicKeyX, Y: oAuthPublicKeyY, privateKey: oAuthKey, getOnly: isNewKey)
                metadataNonce = BigInt(nonce.nonce?.addLeading0sForLength64() ?? "0", radix: 16) ?? BigInt(0)
                typeOfUser = UserType(rawValue: nonce.typeOfUser?.lowercased() ?? "v1")!
                if typeOfUser == .v2 {
                    pubNonce = nonce.pubNonce
                    let publicNonce = KeyUtils.getPublicKeyFromCoords(pubKeyX: pubNonce!.x, pubKeyY: pubNonce!.y)
                    finalPubKey = try KeyUtils.combinePublicKeys(keys: [oAuthPublicKey, publicNonce])
                } else {
                    typeOfUser = .v1
                    metadataNonce = BigInt(try await MetadataUtils.getMetadata(legacyMetadataHost: legacyMetadataHost, dictionary: ["pub_key_X": oAuthPublicKeyX, "pub_key_Y": oAuthPublicKeyY]))
                    let privateKeyWithNonce = (BigInt(oAuthKey.addLeading0sForLength64(), radix: 16)! + BigInt(metadataNonce)).modulus(KeyUtils.getOrderOfCurve())
                    finalPubKey = try SecretKey(hex: privateKeyWithNonce.magnitude.serialize().hexString.addLeading0sForLength64()).toPublic().serialize(compressed: false)
                }
            } else {
                typeOfUser = .v1
                metadataNonce = BigInt(try await MetadataUtils.getMetadata(legacyMetadataHost: legacyMetadataHost, dictionary: ["pub_key_X": oAuthPublicKeyX, "pub_key_Y": oAuthPublicKeyY]))
                let privateKeyWithNonce = (BigInt(oAuthKey.addLeading0sForLength64(), radix: 16)! + BigInt(metadataNonce)).modulus(KeyUtils.getOrderOfCurve())
                finalPubKey = try SecretKey(hex: privateKeyWithNonce.magnitude.serialize().hexString.addLeading0sForLength64()).toPublic().serialize(compressed: false)
            }
        } else {
            typeOfUser = .v2
            let oAuthPubKey = KeyUtils.getPublicKeyFromCoords(pubKeyX: oAuthPublicKeyX, pubKeyY: oAuthPublicKeyY)
            if thresholdNonceData!.pubNonce != nil {
                let publicNonce = KeyUtils.getPublicKeyFromCoords(pubKeyX: thresholdNonceData!.pubNonce!.x, pubKeyY: thresholdNonceData!.pubNonce!.y)
                finalPubKey = try KeyUtils.combinePublicKeys(keys: [oAuthPubKey, publicNonce])
                pubNonce = PubNonce(x: thresholdNonceData!.pubNonce!.x, y: thresholdNonceData!.pubNonce!.y)
            } else {
                finalPubKey = oAuthPubKey
            }
        }

        if finalPubKey == nil {
            throw TorusUtilError.retrieveOrImportShareError
        }

        let oAuthKeyAddress = try KeyUtils.generateAddressFromPubKey(publicKeyX: oAuthPublicKeyX, publicKeyY: oAuthPublicKeyY)

        let (finalPubX, finalPubY) = try KeyUtils.getPublicKeyCoords(pubKey: finalPubKey!)
        let finalEvmAddress = try KeyUtils.generateAddressFromPubKey(publicKeyX: finalPubX, publicKeyY: finalPubY)

        var finalPrivKey = ""
        if typeOfUser == .v1 || (typeOfUser == .v2 && metadataNonce > BigInt(0)) {
            let privateKeyWithNonce = ((BigInt(oAuthKey.addLeading0sForLength64(), radix: 16) ?? BigInt(0)) + metadataNonce).modulus(KeyUtils.getOrderOfCurve())
            finalPrivKey = privateKeyWithNonce.magnitude.serialize().hexString.addLeading0sForLength64()
        }

        var isUpgraded: Bool?
        if typeOfUser == .v2 {
            isUpgraded = metadataNonce == BigInt(0)
        }

        return TorusKey(
            finalKeyData: TorusKey.FinalKeyData(
                evmAddress: finalEvmAddress,
                X: finalPubX,
                Y: finalPubY,
                privKey: finalPrivKey),
            oAuthKeyData: TorusKey.OAuthKeyData(
                evmAddress: oAuthKeyAddress,
                X: oAuthPublicKeyX,
                Y: oAuthPublicKeyY,
                privKey: oAuthKey),
            sessionData: TorusKey.SessionData(
                sessionTokenData: sessionTokenDatas,
                sessionAuthKey: sessionAuthKeySerialized),
            metadata: TorusPublicKey.Metadata(
                pubNonce: pubNonce,
                nonce: metadataNonce.magnitude,
                typeOfUser: typeOfUser,
                upgraded: isUpgraded,
                serverTimeOffset: serverTimeOffsetResponse),
            nodesData: TorusKey.NodesData(
                nodeIndexes: nodeIndexes.filter({ $0 != nil }).map({ $0! })
            )
        )
    }
}
