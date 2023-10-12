//
//  TorusUtils+extension.swift
//
//
//  Created by Shubham on 25/3/20.
//

import CryptoSwift
// import FetchNodeDetails
import Foundation

#if canImport(secp256k1)
    import secp256k1
#endif
import BigInt
import CryptoKit
import OSLog

import AnyCodable
import CommonSources
import FetchNodeDetails

extension TorusUtils {
    // MARK: - utils

    internal func combinations<T>(elements: ArraySlice<T>, k: Int) -> [[T]] {
        if k == 0 {
            return [[]]
        }

        guard let first = elements.first else {
            return []
        }

        let head = [first]
        let subcombos = combinations(elements: elements.dropFirst(), k: k - 1)
        var ret = subcombos.map { head + $0 }
        ret += combinations(elements: elements.dropFirst(), k: k)

        return ret
    }

    internal func combinations<T>(elements: [T], k: Int) -> [[T]] {
        return combinations(elements: ArraySlice(elements), k: k)
    }

    internal func makeUrlRequest(url: String, httpMethod: HTTPMethod = .post) throws -> URLRequest {
        guard
            let url = URL(string: url)
        else {
            throw TorusUtilError.runtime("Invalid Url \(url)")
        }
        var rq = URLRequest(url: url)
        rq.httpMethod = httpMethod.name
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        return rq
    }

    internal func thresholdSame<T: Hashable>(arr: [T], threshold: Int) -> T? {
        var hashmap = [T: Int]()
        for (_, value) in arr.enumerated() {
            if let _ = hashmap[value] {
                hashmap[value]! += 1
            } else {
                hashmap[value] = 1
            }
            if hashmap[value] == threshold {
                return value
            }
        }
        return nil
    }

    internal func isLegacyNetwork() -> Bool {
        if case .legacy = network {
            return true
        }
        return false
    }

    internal func isMigratedLegacyNetwork() -> Bool {
        if case let .legacy(legacyNetwork) = network {
            let legacyRoute = legacyNetwork.migration_map
            if !legacyRoute.migrationCompleted {
                return true
            }
            return false
        }
        return false
    }

    // MARK: - metadata API

    internal func getMetadata(dictionary: [String: String]) async throws -> BigUInt {
        let encoded: Data?
        do {
            encoded = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            throw error
        }

        guard let encodedUnwrapped = encoded else {
            throw TorusUtilError.runtime("Unable to serialize dictionary into JSON. \(dictionary)")
        }
        var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get")
        request.httpBody = encodedUnwrapped
        do {
            let val = try await urlSession.data(for: request)
            let data = try JSONSerialization.jsonObject(with: val.0) as? [String: Any] ?? [:]
            os_log("getMetadata: %@", log: getTorusLogger(log: TorusUtilsLogger.network, type: .info), type: .info, data)
            guard
                let msg: String = data["message"] as? String,
                let ret = BigUInt(msg, radix: 16)
            else {
                throw TorusUtilError.decodingFailed("Message value not correct or nil in \(data)")
            }
            return ret
        } catch {
            return BigUInt("0", radix: 16)!
        }
    }

    internal func getOrSetNonce(x: String, y: String, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResult {
        var data: Data
        let msg = getOnly ? "getNonce" : "getOrSetNonce"
        do {
            if privateKey != nil {
                let val = try generateParams(message: msg, privateKey: privateKey!)
                let encoder = JSONEncoder();
                encoder.outputFormatting = .sortedKeys
                data = try encoder.encode(val)
            } else {
                let dict: [String: Any] = ["pub_key_X": x, "pub_key_Y": y, "set_data": ["data": msg]]
                data = try JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
            }
            var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get_or_set_nonce")
            request.httpBody = data
            let val = try await urlSession.data(for: request)
            let decoded = try JSONDecoder().decode(GetOrSetNonceResult.self, from: val.0)
            return decoded
        } catch let error {
            throw error
        }
    }

    internal func generateParams(message: String, privateKey: String) throws -> MetadataParams {
        do {
            let privKeyData = Data(hex: privateKey)
            // this pubkey is not being padded in backend as well on web, so do not pad here.
            guard var publicKey = SECP256K1.privateKeyToPublicKey(privateKey: privKeyData), let serializedPublicKey = SECP256K1.serializePublicKey(publicKey: &publicKey, compressed: false)?.hexString
            else {
                throw TorusUtilError.runtime("invalid priv key")
            }

            let timeStamp = String(BigUInt(serverTimeOffset + Date().timeIntervalSince1970), radix: 16)
            let setData: MetadataParams.SetData = .init(data: message, timestamp: timeStamp)
            let encodedData = try JSONEncoder().encode(setData)

            let hash = keccak256Data(encodedData)
            guard let sigData = SECP256K1.signForRecovery(hash: hash, privateKey: privKeyData).serializedSignature,
                  var sig = SECP256K1.parseSignature(signature: sigData),
                  var recoveredKey = SECP256K1.recoverPublicKey(hash: hash, recoverableSignature: &sig) else {
                throw TorusUtilError.runtime("sign for recovery hash failed")
            }

            guard let recoveryKeySerialized = SECP256K1.serializePublicKey(publicKey: &recoveredKey, compressed: false)?.hexString
            else {
                throw TorusUtilError.runtime("invalid public key")
            }

            if recoveryKeySerialized != serializedPublicKey {
                throw TorusUtilError.runtime("recover from signature failed")
            }

            return .init(pub_key_X: String(serializedPublicKey.suffix(128).prefix(64)), pub_key_Y: String(serializedPublicKey.suffix(64)), setData: setData, signature: sigData.base64EncodedString())
        } catch let error {
            throw error
        }
    }

    // MARK: - getShareOrKeyAssign

    private func getShareOrKeyAssign(endpoints: [String], nodeSigs: [CommitmentRequestResponse], verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String: Any] = [:]) async throws -> [URLRequest] {
        _ = createURLSession()
        _ = Int(endpoints.count / 2) + 1
        var rpcdata: Data = Data()

        let loadedStrings = extraParams
        let valueDict = ["idtoken": idToken,
                         "nodesignatures": nodeSigs,
                         "verifieridentifier": verifier,
                         "verifier_id": verifierParams.verifier_id,
                         "extended_verifier_id": verifierParams.extended_verifier_id,
        ] as [String: Codable]

        let keepingCurrent = loadedStrings.merging(valueDict) { current, _ in current }
        let finalItem = keepingCurrent.merging(verifierParams.additionalParams) { current, _ in current }

        let params = ["encrypted": "yes",
                      "use_temp": true,
                      "one_key_flow": true,
                      "item": AnyCodable([finalItem]),
        ] as [String: AnyCodable]

        let dataForRequest = ["jsonrpc": "2.0",
                              "id": 10,
                              "method": AnyCodable(JRPC_METHODS.GET_SHARE_OR_KEY_ASSIGN),
                              "params": AnyCodable(params),
        ] as [String: AnyCodable]

        do {
            rpcdata = try JSONEncoder().encode(dataForRequest)
        } catch {
            os_log("get share or key assign - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }
//        print("rpcdata", String(data: rpcdata, encoding: .utf8)!)

        // Create Array of URLRequest Promises

        var requestArray = [URLRequest]()

        for endpoint in endpoints {
            do {
                var request = try makeUrlRequest(url: endpoint, httpMethod: .post)
                request.httpBody = rpcdata
                requestArray.append(request)
            } catch {
                throw error
            }
        }

        return requestArray
    }

    private func reconstructKey(decryptedShares: [Int: String], thresholdPublicKey: KeyAssignment.PublicKey) throws -> String? {
        // run lagrange interpolation on all subsets, faster in the optimistic scenario than berlekamp-welch due to early exit
        let allCombis = kCombinations(s: decryptedShares.count, k: 3)
        var returnedKey: String?

        for j in 0 ..< allCombis.count {
            let currentCombi = allCombis[j]
            let currentCombiShares = decryptedShares.enumerated().reduce(into: [Int: String]()) { acc, current in
                let (index, curr) = current
                if currentCombi.contains(index) {
                    acc[curr.key] = curr.value
                }
            }
            let derivedPrivateKey = try lagrangeInterpolation(shares: currentCombiShares, offset: 0)
            let derivedPrivateKeyHex = derivedPrivateKey

            guard Data(hexString: derivedPrivateKeyHex) != nil else {
                continue
            }
            guard let decryptedPubKey = SECP256K1.privateToPublic(privateKey: Data(hex: derivedPrivateKeyHex.addLeading0sForLength64()))?.toHexString() else {
                throw TorusUtilError.runtime("Decrypted SECP256K1 private key is invalid")
            }
            print("decryptedPubKey", decryptedPubKey, derivedPrivateKey)
            let decryptedPubKeyX = String(decryptedPubKey.suffix(128).prefix(64))
            let decryptedPubKeyY = String(decryptedPubKey.suffix(64))
            if decryptedPubKeyX == thresholdPublicKey.X.addLeading0sForLength64() && decryptedPubKeyY == thresholdPublicKey.Y.addLeading0sForLength64() {
                returnedKey = derivedPrivateKey
                break
            }
        }

        return returnedKey
    }

    // MARK: - retrieveShare

    // TODO: add importShare functionality later
    internal func retrieveShare(
        legacyMetadataHost: String,
        allowHost: String,
        enableOneKey: Bool,
        network: TorusNetwork,
        clientId: String,
        endpoints: [String],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        extraParams: [String: Any] = [:]
    ) async throws -> TorusKey {
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        guard
            let sessionAuthKey = generatePrivateKeyData(),
            var publicKey = SECP256K1.privateKeyToPublicKey(privateKey: sessionAuthKey),
            let serializedPublicKey = SECP256K1.serializePublicKey(publicKey: &publicKey, compressed: false)?.hexString
        else {
            throw TorusUtilError.runtime("Unable to generate SECP256K1 keypair.")
        }

        // Split key in 2 parts, X and Y
        // let publicKeyHex = publicKey.toHexString()
        let pubKeyX = String(serializedPublicKey.suffix(128).prefix(64))
        let pubKeyY = String(serializedPublicKey.suffix(64))

        // Hash the token from OAuth login

        let timestamp = String(Int(getTimestamp()))
        let hashedToken = idToken.sha3(.keccak256)

        let nodeSigs = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
        os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, nodeSigs)
        var promiseArrRequest = [URLRequest]()

        // TODO: make sure we have only complete requests in promiseArrRequest?

        promiseArrRequest = try await getShareOrKeyAssign(endpoints: endpoints, nodeSigs: nodeSigs, verifier: verifier, verifierParams: verifierParams, idToken: idToken, extraParams: extraParams)

        var thresholdNonceData: GetOrSetNonceResult?
        var pubkeyArr = [KeyAssignment.PublicKey]()
        var isNewKeyArr: [String] = []
        var completeShareRequestResponseArr = [ShareRequestResult]()
        var thresholdPublicKey: KeyAssignment.PublicKey?

        try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { group in

            for (i, rq) in promiseArrRequest.enumerated() {
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
                    switch val {
                    case let .success(model):
                        let data = model.data
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        os_log("retrieveShare promise - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")

                        if decoded.error != nil {
                            os_log("retrieveShare promise - decode error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                            throw TorusUtilError.runtime(decoded.error?.message ?? "")
                        }

                        // Ensure that we don't add bad data to result arrays.
                        guard
                            let decodedResult = decoded.result as? ShareRequestResult
                        else { throw TorusUtilError.decodingFailed("ShareReqeust error decoding error : \(decoded), can't decode into shareRequestResult") }

                        isNewKeyArr.append(decodedResult.isNewKey)
                        completeShareRequestResponseArr.append(decodedResult)
                        let keyObj = decodedResult.keys
                        if let first = keyObj.first {
                            let pubkey = first.publicKey
                            let nonceData = first.nonceData
                            let pubNonce = nonceData?.pubNonce?.x

                            pubkeyArr.append(pubkey)
                            if thresholdNonceData == nil && verifierParams.extended_verifier_id == nil {
                                if pubNonce != "" {
                                    thresholdNonceData = nonceData
                                }
                            }
                            //                            pubkeyArr.append(pubkey)
                            guard let result = thresholdSame(arr: pubkeyArr, threshold: threshold)
                            else {
                                throw TorusUtilError.thresholdError
                            }

                            thresholdPublicKey = result

                            if thresholdPublicKey?.X == nil {
                                throw TorusUtilError.thresholdError
                            }

                            if thresholdNonceData == nil && verifierParams.extended_verifier_id == nil && !isLegacyNetwork() {
                                throw TorusUtilError.metadataNonceMissing
                            }

                            return
                        }

                    case let .failure(error):
                        throw error
                    }
                } catch {
                    os_log("retrieveShare promise - share request error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug))
                }
            }

            os_log("retrieveShare - invalid result from nodes, threshold number of public key results are not matching", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error)
            throw TorusUtilError.thresholdError
        })

        // optimistically run lagrange interpolation once threshold number of shares have been received
        // this is matched against the user public key to ensure that shares are consistent
        // Note: no need of thresholdMetadataNonce for extended_verifier_id key
        if completeShareRequestResponseArr.count >= threshold {
            if thresholdPublicKey?.X != nil && (thresholdNonceData != nil && thresholdNonceData?.pubNonce?.x != "" || verifierParams.extended_verifier_id != nil || isLegacyNetwork()) {
                // Code block to execute if all conditions are true
                var shares = [String]()
                var sessionTokenSigPromises = [String?]()
                var sessionTokenPromises = [String?]()
                var nodeIndexes = [Int]()
                var sessionTokenData = [SessionToken?]()

                guard let isNewKey = thresholdSame(arr: isNewKeyArr, threshold: threshold)
                else {
                    os_log("retrieveShare - invalid result from nodes, threshold number of is_new_key results are not matching", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error)
                    throw TorusUtilError.thresholdError
                }

                for currentShareResponse in completeShareRequestResponseArr {
                    let sessionTokens = currentShareResponse.sessionTokens
                    let sessionTokenMetadata = currentShareResponse.sessionTokenMetadata
                    let sessionTokenSigs = currentShareResponse.sessionTokenSigs
                    let sessionTokenSigMetadata = currentShareResponse.sessionTokenSigMetadata
                    let keys = currentShareResponse.keys

                    if sessionTokenSigs.count > 0 {
                        // decrypt sessionSig if enc metadata is sent
                        if sessionTokenSigMetadata.first?.ephemPublicKey != nil {
                            sessionTokenSigPromises.append(try? decryptNodeData(eciesData: sessionTokenSigMetadata[0], ciphertextHex: sessionTokenSigs[0], privKey: sessionAuthKey.hexString.addLeading0sForLength64()))
                        } else {
                            sessionTokenSigPromises.append(sessionTokenSigs[0])
                        }
                    } else {
                        sessionTokenSigPromises.append(nil)
                    }

                    if sessionTokens.count > 0 {
                        if sessionTokenMetadata.first?.ephemPublicKey != nil {
                            sessionTokenPromises.append(try? decryptNodeData(eciesData: sessionTokenMetadata[0], ciphertextHex: sessionTokens[0], privKey: sessionAuthKey.hexString.addLeading0sForLength64()))
                        } else {
                            sessionTokenPromises.append(sessionTokenSigs[0])
                        }
                    } else {
                        sessionTokenPromises.append(nil)
                    }

                    if keys.count > 0 {
                        let latestKey = currentShareResponse.keys[0]
                        nodeIndexes.append(Int(latestKey.nodeIndex))
                        let data = Data(base64Encoded: latestKey.share, options: [])!
                        guard let ciphertextHex = String(data: data, encoding: .ascii) else {
                            throw TorusUtilError.decodingFailed()
                        }
                        let decryptedShare = try decryptNodeData(eciesData: latestKey.shareMetadata, ciphertextHex: ciphertextHex, privKey: sessionAuthKey.hexString.addLeading0sForLength64())
                        shares.append(decryptedShare.addLeading0sForLength64())
                    } else {
                        os_log("retrieveShare -  0 keys returned from nodes", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error)
                        throw TorusUtilError.thresholdError
                    }
                }

                let validTokens = sessionTokenPromises.filter { token in
                    if let _ = token {
                        return true
                    }
                    return false
                }

                if verifierParams.extended_verifier_id == nil && validTokens.count < threshold {
                    os_log("retrieveShare - Insufficient number of session tokens from nodes, required: %@, found: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, threshold, validTokens.count)
                    throw TorusUtilError.apiRequestFailed
                }

                let validSigs = sessionTokenSigPromises.filter { sig in
                    if let _ = sig {
                        return true
                    }
                    return false
                }

                if verifierParams.extended_verifier_id == nil && validSigs.count < threshold {
                    os_log("retrieveShare - Insufficient number of session signatures from nodes, required: %@, found: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, threshold, validSigs.count)
                    throw TorusUtilError.apiRequestFailed
                }

                for (index, x) in sessionTokenPromises.enumerated() {
                    if x == nil {
                        sessionTokenData.append(nil)
                    } else {
                        let token = x!
                        let signature = sessionTokenSigPromises[index] // .toHexString()
                        let nodePubX = completeShareRequestResponseArr[index].nodePubX
                        let nodePubY = completeShareRequestResponseArr[index].nodePubY

                        sessionTokenData.append(SessionToken(token: token, signature: signature!, node_pubx: nodePubX, node_puby: nodePubY))
                    }
                }

                let sharesWithIndex = shares.enumerated().reduce(into: [Int: String]()) { acc, current in
                    let (index, curr) = current
                    acc[nodeIndexes[index]] = curr
                }

                let returnedKey = try reconstructKey(decryptedShares: sharesWithIndex, thresholdPublicKey: thresholdPublicKey!)
                if returnedKey == nil {
                    throw TorusUtilError.privateKeyDeriveFailed
                }

                guard let oAuthKey = returnedKey else {
                    throw TorusUtilError.privateKeyDeriveFailed
                }

//                let decryptedPubKey = SECP256K1.privateToPublic(privateKey: Data(hex: oAuthKey) )?.toHexString()

                let oAuthKeyBigInt = BigInt(oAuthKey, radix: 16)!

                guard let derivedPrivateKeyData = Data(hexString: oAuthKey) else {
                    throw TorusUtilError.privateKeyDeriveFailed
                }

                let oAuthPubKey = SECP256K1.privateToPublic(privateKey: derivedPrivateKeyData.addLeading0sForLength64())?.toHexString()
                let oauthPubKeyX = String(oAuthPubKey!.suffix(128).prefix(64))
                let oauthPubKeyY = String(oAuthPubKey!.suffix(64))

                var metadataNonce = BigInt(thresholdNonceData?.nonce ?? "0", radix: 16) ?? BigInt(0)
                _ = (oAuthKeyBigInt + metadataNonce).modulus(modulusValue)

                var pubKeyNonceResult: PubNonce?
                var typeOfUser: UserType = .v1

                var finalPubKey = "04" + oauthPubKeyX.addLeading0sForLength64() + oauthPubKeyY.addLeading0sForLength64()
                if verifierParams.extended_verifier_id != nil {
                    typeOfUser = .v2
                    // For TSS key, no need to add pub nonce
                    finalPubKey = String(finalPubKey.suffix(128))
                } else if case .legacy = self.network {
                    if self.enableOneKey {
                        // get or set nonce based on isNewKey variable
                        let nonceResult = try await getOrSetNonce(x: oauthPubKeyX, y: oauthPubKeyY, privateKey: oAuthKey, getOnly: isNewKey == "false")
                        //                        BigInt( Data(hex: nonceResult.nonce ?? "0"))
                        metadataNonce = BigInt(nonceResult.nonce ?? "0", radix: 16)!
                        let usertype = nonceResult.typeOfUser

                        if usertype == "v2" {
                            let pubNonceX = nonceResult.pubNonce?.x
                            let pubNonceY = nonceResult.pubNonce?.y
                            typeOfUser = .v2
                            let pubkey2 = "04" + pubNonceX!.addLeading0sForLength64() + pubNonceY!.addLeading0sForLength64()
                            let combined = combinePublicKeys(keys: [finalPubKey, pubkey2], compressed: false)
                            finalPubKey = combined
                            pubKeyNonceResult = .init(x: pubNonceX!, y: pubNonceY!)
                        } else {
                            typeOfUser = .v1
                            // for imported keys in legacy networks
                            metadataNonce = BigInt(try await getMetadata(dictionary: ["pub_key_X": oauthPubKeyX, "pub_key_Y": oauthPubKeyY]))
                            let privateKeyWithNonce = (BigInt(oAuthKey, radix: 16)! + BigInt(metadataNonce)).modulus(modulusValue)
                            finalPubKey = String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()
                        }
                    } else {
                        typeOfUser = .v1
                        // for imported keys in legacy networks
                        metadataNonce = BigInt(try await getMetadata(dictionary: ["pub_key_X": oauthPubKeyX, "pub_key_Y": oauthPubKeyY]))
                        let privateKeyWithNonce = (BigInt(oAuthKey, radix: 16)! + BigInt(metadataNonce)).modulus(modulusValue)
                        finalPubKey = String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()
                    }
                } else {
                    typeOfUser = .v2

                    let pubNonceX = thresholdNonceData!.pubNonce!.x
                    let pubNonceY = thresholdNonceData!.pubNonce!.y
                    let pubkey2 = "04" + pubNonceX.addLeading0sForLength64() + pubNonceY.addLeading0sForLength64()
                    let combined = combinePublicKeys(keys: [finalPubKey, pubkey2], compressed: false)
                    finalPubKey = combined
                    pubKeyNonceResult = .init(x: pubNonceX, y: pubNonceY)
                }

                let (oAuthKeyX, oAuthKeyY) = try getPublicKeyPointFromPubkeyString(pubKey: oAuthPubKey!)
                let oAuthKeyAddress = try generateAddressFromPubKey(publicKeyX: oAuthKeyX, publicKeyY: oAuthKeyY)

                var finalPrivKey = ""

                if typeOfUser == .v1 || (typeOfUser == .v2 && metadataNonce > BigInt(0)) {
                    let privateKeyWithNonce = ((BigInt(oAuthKey, radix: 16) ?? BigInt(0)) + metadataNonce).modulus(modulusValue)
                    finalPrivKey = String(privateKeyWithNonce, radix: 16).addLeading0sForLength64()
                }

                let (finalPubX, finalPubY) = try getPublicKeyPointFromPubkeyString(pubKey: finalPubKey)
                // deriving address from pub key coz pubkey is always available
                // but finalPrivKey won't be available for  v2 user upgraded to 2/n
                let finalEvmAddress = try generateAddressFromPubKey(publicKeyX: finalPubX, publicKeyY: finalPubY)

                var isUpgraded: Bool?

                switch typeOfUser {
                case .v1:
                    isUpgraded = nil
                case .v2:
                    isUpgraded = metadataNonce == BigInt(0)
                }

                return TorusKey(
                    finalKeyData: .init(
                        evmAddress: finalEvmAddress,
                        X: finalPubX.addLeading0sForLength64(),
                        Y: finalPubY.addLeading0sForLength64(),
                        privKey: finalPrivKey
                    ),
                    oAuthKeyData: .init(
                        evmAddress: oAuthKeyAddress,
                        X: oAuthKeyX,
                        Y: oAuthKeyY,
                        privKey: oAuthKey
                    ),
                    sessionData: .init(
                        sessionTokenData: sessionTokenData,
                        sessionAuthKey: sessionAuthKey.hexString.addLeading0sForLength64()
                    ),
                    metadata: .init(
                        pubNonce: pubKeyNonceResult,
                        nonce: BigUInt(metadataNonce),
                        typeOfUser: typeOfUser,
                        upgraded: isUpgraded
                    ),
                    nodesData: .init(nodeIndexes: nodeIndexes)
                )
            }
        }
        throw TorusUtilError.retrieveOrImportShareError
    }

    // MARK: - commitment request

    internal func commitmentRequest(endpoints: [String], verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) async throws -> [CommitmentRequestResponse] {
        let session = createURLSession()

        let threshold = Int(endpoints.count / 4) * 3 + 1
        let encoder = JSONEncoder()
        var failedLookUpCount = 0
        let jsonRPCRequest = JSONRPCrequest(
            method: JRPC_METHODS.COMMITMENT_REQUEST,
            params: ["messageprefix": "mug00",
                     "tokencommitment": tokenCommitment,
                     "temppubx": pubKeyX,
                     "temppuby": pubKeyY,
                     "verifieridentifier": verifier,
                     "timestamp": timestamp]
        )

        guard let rpcdata = try? encoder.encode(jsonRPCRequest)
        else {
            throw TorusUtilError.runtime("Unable to encode request. \(jsonRPCRequest)")
        }

        // Build promises array
        var nodeSignatures = [CommitmentRequestResponse]()
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
        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { group in

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
                        let data = model.data
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        os_log("commitmentRequest - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")

                        // TODO: this error block can't catch error
                        if decoded.error != nil {
                            os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                            throw TorusUtilError.runtime(decoded.error?.message ?? "")
                        }

                        // Ensure that we don't add bad data to result arrays.
                        guard
                            let response = decoded.result as? CommitmentRequestResponse
                        else {
                            throw TorusUtilError.decodingFailed("CommitmentRequestResponse could not be decoded")
                        }

                        // Check if k+t responses are back
                        let val = CommitmentRequestResponse(data: response.data, nodepubx: response.nodepubx, nodepuby: response.nodepuby, signature: response.signature)
                        nodeSignatures.append(val)
                        if nodeSignatures.count >= threshold {
                            os_log("commitmentRequest - nodeSignatures: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, nodeSignatures)
                            session.invalidateAndCancel()
                            return nodeSignatures
                        }
                    case let .failure(error):
                        os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    }
                } catch {
                    failedLookUpCount += 1
                    os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    if failedLookUpCount > endpoints.count - threshold {
                        os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, TorusUtilError.runtime("threshold node unavailable").localizedDescription)
                        session.invalidateAndCancel()
                        throw error
                    }
                }
            }
            throw TorusUtilError.commitmentRequestFailed
        })
    }

    internal func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
        guard let params = params, let message = params["message"] as? String else {
            return BigUInt(0)
        }
        return BigUInt(message, radix: 16)!
    }

    internal func decryptNodeData(eciesData: EciesHex, ciphertextHex: String, privKey: String, padding: Padding = .pkcs7) throws -> String {
        let eciesOpts = ECIES(
            iv: eciesData.iv,
            ephemPublicKey: eciesData.ephemPublicKey,
            ciphertext: ciphertextHex,
            mac: eciesData.mac
        )

        let decryptedSigBuffer = try decrypt(privateKey: privKey, opts: eciesOpts, padding: padding).toHexString()
        return decryptedSigBuffer
    }

    public func encryptData(privkeyHex: String, _ dataToEncrypt: String) throws -> String {
        guard let pubKey = SECP256K1.privateToPublic(privateKey: privkeyHex.hexa.data)?.toHexString() else {
            throw TorusUtilError.runtime("Invalid private key hex")
        }
        let encParams = try encrypt(publicKey: pubKey, msg: dataToEncrypt, opts: nil)
        let data = try JSONEncoder().encode(encParams)
        guard let string = String(data: data, encoding: .utf8) else { throw TorusUtilError.runtime("Invalid String from enc Params") }
        return string
    }

    public func encrypt(publicKey: String, msg: String, opts: Ecies? = nil) throws -> Ecies {
        let ephemPrivateKey = try secp256k1.KeyAgreement.PrivateKey()
        let ephemPublicKey = ephemPrivateKey.publicKey

        let sharedSecret = try SECP256K1.ecdh(publicKey: ephemPublicKey, privateKey: ephemPrivateKey)

        let encryptionKey = sharedSecret[0 ..< 32].bytes
        let macKey = sharedSecret[32 ..< 64].bytes
        let iv: [UInt8] = (opts?.iv ?? SECP256K1.randomBytes(length: 16)?.toHexString())?.hexa ?? []

        let aes = try AES(key: encryptionKey, blockMode: CBC(iv: iv), padding: .pkcs7)
        let ciphertext = try aes.encrypt(msg.customBytes())
        var dataToMac: [UInt8] = iv
        dataToMac.append(contentsOf: ephemPublicKey.dataRepresentation)
        dataToMac.append(contentsOf: ciphertext)
        let mac = try? HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(dataToMac)
        return .init(iv: iv.toHexString(), ephemPublicKey: ephemPublicKey.dataRepresentation.hexString,
                     ciphertext: ciphertext.toHexString(), mac: mac?.toHexString() ?? "")
    }

    // MARK: - decrypt shares

    internal func decryptIndividualShares(shares: [Int: RetrieveDecryptAndReconstuctResponseModel], privateKey: String) throws -> [Int: String] {
        var result = [Int: String]()

        for (_, el) in shares.enumerated() {
            let nodeIndex = el.key

            let publicKeyHex = el.value.ephemPublicKey
            let sharedSecret = try SECP256K1.ecdhWithHex(pubKeyHex: publicKeyHex, privateKeyHex: privateKey)

            guard
                let share = el.value.share.fromBase64()?.hexa
            else {
                throw TorusUtilError.decryptionFailed
            }

            do {
                // AES-CBCblock-256
                let aesKey = sharedSecret[0 ..< 32].bytes
                _ = sharedSecret[32 ..< 64].bytes // TODO: check mac
                let iv = el.value.iv.hexa
                let aes = try AES(key: aesKey, blockMode: CBC(iv: iv), padding: .pkcs7)
                let decryptData = try aes.decrypt(share)
                result[nodeIndex] = decryptData.hexa
            } catch let err {
                result[nodeIndex] = TorusUtilError.decodingFailed(err.localizedDescription).debugDescription
            }
            if shares.count == result.count {
                return result
            }
        }
        throw TorusUtilError.runtime("decryptIndividualShares func failed")
    }

    // MARK: - Lagrange interpolation

    internal func thresholdLagrangeInterpolation(data filteredData: [Int: String], endpoints: [String], lookupPubkeyX: String, lookupPubkeyY: String) throws -> (String, String, String) {
        // all possible combinations of share indexes to interpolate
        let shareCombinations = combinations(elements: Array(filteredData.keys), k: Int(endpoints.count / 2) + 1)
        for shareIndexSet in shareCombinations {
            var sharesToInterpolate: [Int: String] = [:]
            shareIndexSet.forEach { sharesToInterpolate[$0] = filteredData[$0] }
            do {
                let data = try lagrangeInterpolation(shares: sharesToInterpolate)
                // Split key in 2 parts, X and Y
                let finalPrivateKey = Data(hex: data)
                guard var publicKey = SECP256K1.privateKeyToPublicKey(privateKey: finalPrivateKey),
                      let serializedPublicKey = SECP256K1.serializePublicKey(publicKey: &publicKey, compressed: false)?.hexString else {
                    throw TorusUtilError.decodingFailed("\(data)")
                }
                let pubKeyX = String(serializedPublicKey.suffix(128).prefix(64))
                let pubKeyY = String(serializedPublicKey.suffix(64))
                os_log("retrieveDecryptAndReconstuct: private key rebuild %@ %@ %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data, pubKeyX, pubKeyY)

                // Verify
                if pubKeyX == lookupPubkeyX && pubKeyY == lookupPubkeyY {
                    return (pubKeyX, pubKeyY, data)
                } else {
                    os_log("retrieveDecryptAndReconstuct: verification failed", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error)
                }
            } catch {
                os_log("retrieveDecryptAndReconstuct: lagrangeInterpolation: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            }
        }
        throw TorusUtilError.interpolationFailed
    }

    internal func lagrangeInterpolation(shares: [Int: String], offset: Int = 1) throws -> String {
        let secp256k1N = modulusValue

        // Convert shares to BigInt(Shares)
        var shareList = [BigInt: BigInt]()
        _ = shares.map { shareList[BigInt($0.key + offset)] = BigInt($0.value.addLeading0sForLength64(), radix: 16) }

        var secret = BigUInt("0") // to support BigInt 4.0 dependency on cocoapods
        var sharesDecrypt = 0

        for (i, share) in shareList {
            var upper = BigInt(1)
            var lower = BigInt(1)
            for (j, _) in shareList {
                if i != j {
                    let negatedJ = j * BigInt(-1)
                    upper = upper * negatedJ
                    upper = upper.modulus(secp256k1N)

                    var temp = i - j
                    temp = temp.modulus(secp256k1N)
                    lower = (lower * temp).modulus(secp256k1N)
                }
            }
            guard
                let inv = lower.inverse(secp256k1N)
            else {
                throw TorusUtilError.decryptionFailed
            }
            var delta = (upper * inv).modulus(secp256k1N)
            delta = (delta * share).modulus(secp256k1N)
            secret = BigUInt((BigInt(secret) + delta).modulus(secp256k1N))
            sharesDecrypt += 1
        }
        let secretString = String(secret.serialize().hexa.suffix(64))
        if sharesDecrypt == shareList.count {
            return secretString
        } else {
            throw TorusUtilError.interpolationFailed
        }
    }

    // MARK: - getPubKeyOrKeyAssign

    internal func getPubKeyOrKeyAssign(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId: String? = nil) async throws -> KeyLookupResult {
        // Encode data
        let encoder = JSONEncoder()
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        var failedLookupCount = 0

        // flag to check if node with index 1 is queried for metadata
        var isNodeOneVisited = false

        let methodName = JRPC_METHODS.GET_OR_SET_KEY

        let params = GetPublicAddressOrKeyAssignParams(verifier: verifier, verifier_id: verifierId, extended_verifier_id: extendedVerifierId, one_key_flow: true, fetch_node_index: true)

        let jsonRPCRequest = JSONRPCrequest(
            method: methodName,
            params: params
        )

        guard let rpcdata = try? encoder.encode(jsonRPCRequest)

        else {
            throw TorusUtilError.encodingFailed("\(jsonRPCRequest)")
        }

        // Create Array of URLRequest Promises

        var resultArray: [KeyLookupResponse] = []
        var requestArray = [URLRequest]()
        for endpoint in endpoints {
            do {
                var request = try makeUrlRequest(url: endpoint)
                request.httpBody = rpcdata
                requestArray.append(request)
            } catch {
                throw error
            }
        }

        var nonceResult: GetOrSetNonceResult?
        var nodeIndexesArray: [Int] = []
        var keyArray: [VerifierLookupResponse?] = []

        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, returning: KeyLookupResult.self) { group in

            for (i, rq) in requestArray.enumerated() {
                group.addTask {
                    do {
                        let val = try await session.data(for: rq)
                        return .success(.init(data: val.0, urlResponse: val.1, index: i))
                    } catch {
                        return .failure(error)
                    }
                }
            }

            // this is serial execution
            // TODO: convert this to some function implementation as we do in web
            for try await val in group {
                do {
                    switch val {
                    case let .success(model):
                        // print( try JSONSerialization.jsonObject(with: model.data) )
                        let data = model.data
                        do {
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                            let result = decoded.result as? VerifierLookupResponse

                            if let _ = decoded.error {
                                let error = KeyLookupError.createErrorFromString(errorString: "")
                                throw error
                            } else {
                                let decodedResult = result!
                                keyArray.append(decodedResult)
                                if let k = decodedResult.keys,
                                   let key = k.first {
                                    let model = KeyLookupResponse(pubKeyX: key.pub_key_X, pubKeyY: key.pub_key_Y, address: key.address, isNewKey: decodedResult.is_new_key)

                                    resultArray.append(model)
                                    if let nonceData = key.nonce_data {
                                        let pubNonceX = nonceData.pubNonce?.x
                                        if pubNonceX != nil && pubNonceX != "" && nonceResult == nil {
                                            nonceResult = key.nonce_data
                                        }
                                    }
                                }
                            }
                            let keyResult = thresholdSame(arr: resultArray, threshold: threshold) // Check if threshold is satisfied

                            // proceed if we have key result and either of nonceResult, extendedVerifierId, isLegacyNetwork is
                            // available
                            if keyResult != nil && (nonceResult != nil || extendedVerifierId != nil || isLegacyNetwork()) {
                                if let keyResult = keyResult {
                                    os_log("%@: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, methodName, keyResult.description)
                                    session.invalidateAndCancel()
                                    keyArray.forEach({ result in

                                        if result?.node_index == "1" {
                                            isNodeOneVisited = true
                                        }
                                        if result != nil && result?.node_index != "0" {
                                            nodeIndexesArray.append(Int(result!.node_index)!)
                                        }

                                    })

                                    return KeyLookupResult(keyResult: keyResult, nodeIndexes: nodeIndexesArray, nonceResult: nonceResult)
                                }
                            }
                            throw NSError(domain: "condition not meet", code: 1001)
                        } catch let err {
                            throw err
                        }
                    case let .failure(error):
                        throw error
                    }
                } catch {
                    failedLookupCount += 1
                    os_log("%@: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, methodName, error.localizedDescription)

                    if (isNodeOneVisited && failedLookupCount > (endpoints.count - threshold)) || (failedLookupCount == endpoints.count) {
                        os_log("%@: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, methodName, TorusUtilError.runtime("threshold nodes unavailable").localizedDescription)
                        session.invalidateAndCancel()
                        throw error
                    }
                }
            }

            throw TorusUtilError.runtime("\(methodName) func failed")
        }
    }

    // MARK: - keylookup

    internal func awaitKeyLookup(endpoints: [String], verifier: String, verifierId: String, timeout: Int = 0) async throws -> KeyLookupResponse {
        let durationInNanoseconds = UInt64(timeout * 1000000000)
        try await Task.sleep(nanoseconds: durationInNanoseconds)
        do {
            return try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        } catch {
            throw error
        }
    }

    internal func awaitLegacyKeyLookup(endpoints: [String], verifier: String, verifierId: String, timeout: Int = 0) async throws -> LegacyKeyLookupResponse {
        let durationInNanoseconds = UInt64(timeout * 1000000000)
        try await Task.sleep(nanoseconds: durationInNanoseconds)
        do {
            return try await legacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        } catch {
            throw error
        }
    }

    internal func legacyKeyLookup(endpoints: [String], verifier: String, verifierId: String) async throws -> LegacyKeyLookupResponse {
        // Enode data
        let encoder = JSONEncoder()
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        var failedLookupCount = 0
        let jsonRPCRequest = JSONRPCrequest(
            method: JRPC_METHODS.LEGACY_VERIFIER_LOOKUP_REQUEST,
            params: ["verifier": verifier, "verifier_id": verifierId])
        guard let rpcdata = try? encoder.encode(jsonRPCRequest)
        else {
            throw TorusUtilError.encodingFailed("\(jsonRPCRequest)")
        }
        var allowHostRequest = try makeUrlRequest(url: allowHost, httpMethod: .get)
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "Origin")
        do {
            _ = try await session.data(for: allowHostRequest)
        } catch {
            os_log("KeyLookup: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }

        // Create Array of URLRequest Promises

        var resultArray = [LegacyKeyLookupResponse]()
        var requestArray = [URLRequest]()
        for endpoint in endpoints {
            do {
                var request = try makeUrlRequest(url: endpoint)
                request.httpBody = rpcdata
                requestArray.append(request)
            } catch {
                throw error
            }
        }

        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { [unowned self] group in
            for (i, rq) in requestArray.enumerated() {
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
                    switch val {
                    case let .success(model):
                        let data = model.data
                        do {
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                            os_log("keyLookup: API response: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decoded)")

                            let result = decoded.result
                            let error = decoded.error
                            if let _ = error {
                                let error = KeyLookupError.createErrorFromString(errorString: decoded.error?.data ?? "")
                                throw error
                            } else {
                                guard
                                    let decodedResult = result as? [String: [[String: String]]],
                                    let k = decodedResult["keys"],
                                    let keys = k.first,
                                    let pubKeyX = keys["pub_key_X"],
                                    let pubKeyY = keys["pub_key_Y"],
                                    let keyIndex = keys["key_index"],
                                    let address = keys["address"]
                                else {
                                    throw TorusUtilError.decodingFailed("keys not found in \(result ?? "")")
                                }
                                let model = LegacyKeyLookupResponse(pubKeyX: pubKeyX, pubKeyY: pubKeyY, keyIndex: keyIndex, address: address)
                                resultArray.append(model)
                            }
                            let keyResult = thresholdSame(arr: resultArray, threshold: threshold) // Check if threshold is satisfied

                            if let keyResult = keyResult {
                                os_log("keyLookup: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, keyResult.description)
                                session.invalidateAndCancel()
                                return keyResult
                            }
                        } catch let err {
                            throw err
                        }
                    case let .failure(error):
                        throw error
                    }
                } catch {
                    failedLookupCount += 1
                    os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    if failedLookupCount > (endpoints.count - threshold) {
                        os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, TorusUtilError.runtime("threshold nodes unavailable").localizedDescription)
                        session.invalidateAndCancel()
                        throw error
                    }
                }
            }
            throw TorusUtilError.runtime("keyLookup func failed")
        })
    }

    internal func keyLookup(endpoints: [String], verifier: String, verifierId: String) async throws -> KeyLookupResponse {
        // Enode data
        let encoder = JSONEncoder()
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        var failedLookupCount = 0
        let jsonRPCRequest = JSONRPCrequest(
            method: JRPC_METHODS.LEGACY_VERIFIER_LOOKUP_REQUEST,
            params: ["verifier": verifier, "verifier_id": verifierId])
        guard let rpcdata = try? encoder.encode(jsonRPCRequest)
        else {
            throw TorusUtilError.encodingFailed("\(jsonRPCRequest)")
        }
        var allowHostRequest = try makeUrlRequest(url: allowHost, httpMethod: .get)
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "Origin")
        do {
            _ = try await session.data(for: allowHostRequest)
        } catch {
            os_log("KeyLookup: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }

        // Create Array of URLRequest Promises

        var resultArray = [KeyLookupResponse]()
        var requestArray = [URLRequest]()
        for endpoint in endpoints {
            do {
                var request = try makeUrlRequest(url: endpoint)
                request.httpBody = rpcdata
                requestArray.append(request)
            } catch {
                throw error
            }
        }

        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { [unowned self] group in
            for (i, rq) in requestArray.enumerated() {
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
                    switch val {
                    case let .success(model):
                        let data = model.data
                        do {
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                            os_log("keyLookup: API response: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decoded)")

                            // result of decoded data
                            let result = decoded.result
                            let error = decoded.error
                            if let _ = error {
                                let error = KeyLookupError.createErrorFromString(errorString: decoded.error?.data ?? "")
                                throw error
                            } else {
                                guard
                                    let decodedResult = result as? [String: [[String: Any]]],

                                    let k = decodedResult["keys"],
                                    let keys = k.first,
                                    let pubKeyX = keys["pub_key_X"] as? String,
                                    let pubKeyY = keys["pub_key_Y"] as? String,
                                    let address = keys["address"] as? String
                                else {
                                    throw TorusUtilError.decodingFailed("key not found")
                                }
                                let isNewKey = keys["is_new_key"] as? Bool ?? false
                                let model = KeyLookupResponse(pubKeyX: pubKeyX, pubKeyY: pubKeyY, address: address, isNewKey: isNewKey)
                                resultArray.append(model)
                            }
                            let keyResult = thresholdSame(arr: resultArray, threshold: threshold) // Check if threshold is satisfied

                            if let keyResult = keyResult {
                                os_log("keyLookup: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, keyResult.description)
                                session.invalidateAndCancel()
                                return keyResult
                            }
                        } catch let err {
                            throw err
                        }
                    case let .failure(error):
                        throw error
                    }
                } catch {
                    failedLookupCount += 1
                    os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    if failedLookupCount > (endpoints.count - threshold) {
                        os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, TorusUtilError.runtime("threshold nodes unavailable").localizedDescription)
                        session.invalidateAndCancel()
                        throw error
                    }
                }
            }
            throw TorusUtilError.runtime("keyLookup func failed")
        })
    }

    // MARK: - key assignment

    internal func keyAssign(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, signerHost: String, network: TorusNetwork, firstPoint: Int? = nil, lastPoint: Int? = nil) async throws -> JSONRPCresponse {
        var nodeNum: Int = 0
        var initialPoint: Int = 0
        os_log("KeyAssign: endpoints: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, endpoints)
        if let safeLastPoint = lastPoint {
            nodeNum = safeLastPoint % endpoints.count
        } else {
            nodeNum = Int(floor(Double(Double(arc4random_uniform(1)) * Double(endpoints.count))))
        }
        if nodeNum == firstPoint {
            throw TorusUtilError.runtime("Looped through all")
        }
        if let safefirstPoint = firstPoint {
            initialPoint = safefirstPoint
        }

        let encoder = JSONEncoder()
        if #available(macOS 10.13, *) {
            encoder.outputFormatting = .sortedKeys
        } else {
            // Fallback on earlier versions
        }
        os_log("newEndpoints2 : %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, endpoints)

        let SignerObject = JSONRPCrequest(method: JRPC_METHODS.LEGACY_KEY_ASSIGN, params: ["verifier": verifier, "verifier_id": verifierId])
        do {
            let rpcdata = try encoder.encode(SignerObject)
            var request = try makeUrlRequest(url: signerHost)
            request.addValue(torusNodePubs[nodeNum].getX().lowercased(), forHTTPHeaderField: "pubKeyX")
            request.addValue(torusNodePubs[nodeNum].getY().lowercased(), forHTTPHeaderField: "pubKeyY")
            switch network {
            case let .legacy(network): request.addValue(network.path, forHTTPHeaderField: "network")
            case let .sapphire(network): request.addValue(network.path, forHTTPHeaderField: "network")
            }

            request.httpBody = rpcdata
            do {
                let responseFromSignerData: (Data, URLResponse) = try await urlSession.data(for: request)
                let decodedSignerResponse = try JSONDecoder().decode(SignerResponse.self, from: responseFromSignerData.0)
                os_log("KeyAssign: responseFromSigner: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decodedSignerResponse)")
                let keyassignRequest = KeyAssignRequest(params: ["verifier": verifier, "verifier_id": verifierId], signerResponse: decodedSignerResponse)
                // Combine signer respose and request data
                encoder.outputFormatting = .sortedKeys
                let newData = try encoder.encode(keyassignRequest)
                var request2 = try makeUrlRequest(url: endpoints[nodeNum])
                request2.httpBody = newData
                let keyAssignRequestData: (Data, URLResponse) = try await urlSession.data(for: request2)
                do {
                    let decodedData = try JSONDecoder().decode(JSONRPCresponse.self, from: keyAssignRequestData.0) // User decoder to covert to struct

                    os_log("keyAssign: fullfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decodedData)")
                    return decodedData
                } catch let err {
                    throw TorusUtilError.decodingFailed(err.localizedDescription)
                }
            } catch {
                os_log("KeyAssign: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, "\(error)")
                return try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network, firstPoint: initialPoint, lastPoint: nodeNum + 1)
            }
        } catch let err {
            throw err
        }
    }

    internal func generateNonceMetadataParams(message: String, privateKey: BigInt, nonce: BigInt?) throws -> NonceMetadataParams {
        do {
            let privKeyData = Data(hex: privateKey.serialize().hexString.addLeading0sForLength64())
            guard var publicKey = SECP256K1.privateKeyToPublicKey(privateKey: privKeyData), let serializedPublicKey = SECP256K1.serializePublicKey(publicKey: &publicKey, compressed: false)?.hexString
            else {
                throw TorusUtilError.runtime("invalid priv key")
            }

            let timeStamp = String(BigUInt(serverTimeOffset + Date().timeIntervalSince1970), radix: 16)
            var setData: NonceMetadataParams.SetNonceData = .init(data: message, timestamp: timeStamp)
            if nonce != nil {
                setData.data = String(nonce!, radix: 16).addLeading0sForLength64()
            }
            let encodedData = try JSONEncoder().encode(setData)
            let hash = keccak256Data(encodedData)
            guard let sigData = SECP256K1.signForRecovery(hash: hash, privateKey: privKeyData).serializedSignature,
                  var sig = SECP256K1.parseSignature(signature: sigData),
                  var recoveredKey = SECP256K1.recoverPublicKey(hash: hash, recoverableSignature: &sig) else {
                throw TorusUtilError.runtime("sign for recovery hash failed")
            }

            guard let recoveryKeySerialized = SECP256K1.serializePublicKey(publicKey: &recoveredKey, compressed: false)?.hexString
            else {
                throw TorusUtilError.runtime("invalid public key")
            }

            if recoveryKeySerialized != serializedPublicKey {
                throw TorusUtilError.runtime("recover from signature failed")
            }

            return .init(pub_key_X: String(serializedPublicKey.suffix(128).prefix(64)), pub_key_Y: String(serializedPublicKey.suffix(64)), setData: setData, signature: sigData.base64EncodedString())
        } catch let error {
            throw error
        }
    }

    internal func getPublicKeyPointFromPubkeyString(pubKey: String) throws -> (String, String) {
        let publicKeyHashData = Data.fromHex(pubKey.strip04Prefix())
        guard publicKeyHashData?.count == 64 else {
            throw "Invalid address,"
        }

        let xCoordinateData = publicKeyHashData?.prefix(32).toHexString()
        let yCoordinateData = publicKeyHashData?.suffix(32).toHexString()

        if let x = xCoordinateData, let y = yCoordinateData {
            return (x, y)
        } else {
            throw "invalid address"
        }
    }

    internal func combinePublicKeys(keys: [String], compressed: Bool) -> String {
        let data = keys.map({ Data.fromHex($0)! })
        let added = SECP256K1.combineSerializedPublicKeys(keys: data, outputCompressed: compressed)
        return (added?.toHexString())!
    }

    internal func formatLegacyPublicData(finalKeyResult: KeyLookupResponse, enableOneKey: Bool, isNewKey: Bool) async throws -> TorusPublicKey {
        var finalPubKey: String = ""
        var nonce: BigUInt = 0
        var typeOfUser: TypeOfUser = .v1
        var pubNonce: PubNonce?
        var result: TorusPublicKey
        var nonceResult: GetOrSetNonceResult?
        let pubKeyX = finalKeyResult.pubKeyX
        let pubKeyY = finalKeyResult.pubKeyY
        let (oAuthX, oAuthY) = (pubKeyX.addLeading0sForLength64(), pubKeyY.addLeading0sForLength64())
        if enableOneKey {
            nonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, privateKey: nil, getOnly: !isNewKey)
            nonce = BigUInt(nonceResult?.nonce ?? "0") ?? 0
            typeOfUser = .init(rawValue: nonceResult?.typeOfUser ?? ".v1") ?? .v1
            if typeOfUser == .v1 {
                finalPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                if nonce != BigInt(0) {
                    guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce).serialize().addLeading0sForLength64()) else {
                        throw TorusUtilError.decryptionFailed
                    }
                    finalPubKey = combinePublicKeys(keys: [finalPubKey, noncePublicKey.toHexString()], compressed: false)
                } else {
                    finalPubKey = String(finalPubKey.suffix(128))
                }
            } else if typeOfUser == .v2 {
                pubNonce = nonceResult?.pubNonce
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
            let localPubkeyX = finalKeyResult.pubKeyX
            let localPubkeyY = finalKeyResult.pubKeyY
            finalPubKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
            if localNonce != BigInt(0) {
                let nonce2 = BigInt(localNonce)
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

        let oAuthAddress = try generateAddressFromPubKey(publicKeyX: oAuthX, publicKeyY: oAuthY)
        let finalAddress = try generateAddressFromPubKey(publicKeyX: finalX, publicKeyY: finalY)

        var usertype = ""
        switch typeOfUser {
        case .v1:
            usertype = "v1"
        case .v2:
            usertype = "v2"
        }

        result = TorusPublicKey(
            finalKeyData: .init(
                evmAddress: finalAddress,
                X: finalX.addLeading0sForLength64(),
                Y: finalY.addLeading0sForLength64()
            ),
            oAuthKeyData: .init(
                evmAddress: oAuthAddress,
                X: oAuthX.addLeading0sForLength64(),
                Y: oAuthY.addLeading0sForLength64()
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
    }

    internal func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }

    public func decrypt(privateKey: String, opts: ECIES, padding: Padding = .pkcs7) throws -> Data {
        let sharedSecret = try SECP256K1.ecdhWithHex(pubKeyHex: opts.ephemPublicKey, privateKeyHex: privateKey)

        let aesKey = sharedSecret[0 ..< 32].bytes
        _ = sharedSecret[32 ..< 64].bytes // TODO: check mac
        let iv = opts.iv.hexa

        let aes = try AES(key: aesKey, blockMode: CBC(iv: iv), padding: padding)
        let plaintext = try aes.decrypt(opts.ciphertext.hexa)
        let data = Data(plaintext)
        return data
    }
}

extension Array where Element == UInt8 {
    func uint8Reverse() -> Array {
        var revArr = [Element]()
        for arrayIndex in stride(from: count - 1, through: 0, by: -1) {
            revArr.append(self[arrayIndex])
        }
        return revArr
    }
}
