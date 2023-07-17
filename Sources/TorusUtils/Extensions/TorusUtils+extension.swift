//
//  TorusUtils+extension.swift
//
//
//  Created by Shubham on 25/3/20.
//

//import FetchNodeDetails
import Foundation
#if canImport(secp256k1)
import secp256k1
#endif
import BigInt
import CryptoSwift
import CryptoKit
import OSLog

import FetchNodeDetails
import CommonSources
import AnyCodable

extension TorusUtils {
    
    public func getNewPublicAddress(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId :String? = nil, enableOneKey: Bool) async throws -> TorusPublicKey {
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
//            else if LEGACY_NETWORKS_ROUTE_MAP[self.network] != nil {
////                return formatLegacyPublicKeyData
//            }
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

    
//     func importPrivateKey(
//         endpoints: [String],
//         nodeIndexes: [BigUInt],
//         nodePubKeys: [INodePub],
//         verifier: String,
//         verifierParams: VerifierParams,
//         idToken: String,
//         newPrivateKey: String,
//         extraParams: [String: Any] = [:]

//     ) async throws -> RetrieveSharesResponse {
        
//         if endpoints.count != nodeIndexes.count {
//             throw TorusUtilError.runtime("Length of endpoints array must be the same as length of nodeIndexes array")
//         }
        
//         let threshold = endpoints.count / 2 + 1
//         let degree = threshold - 1
//         var nodeIndexesBigInt: [BigInt] = []
        
//         let privKeyBigInt = BigInt(hex: newPrivateKey) ?? BigInt(0)

//         for nodeIndex in nodeIndexes {

//             nodeIndexesBigInt.append(BigInt(nodeIndex))
//         }
    
//         let randomNonce = BigInt(SECP256K1.generatePrivateKey()!)
        
        
//         let oauthKey = abs(privKeyBigInt - randomNonce) % modulusValue
//         let oauthKeyStr = String(oauthKey, radix: 16).addLeading0sForLength64()
//         guard let oauthKeyData = Data(hex: oauthKeyStr)
//         else {
//             throw TorusUtilError.runtime("invalid oauthkey data")
//         }
        
        
//         guard let oauthPubKey = SECP256K1.privateToPublic(privateKey: oauthKeyData)?.subdata(in: 1 ..< 65).toHexString().padLeft(padChar: "0", count: 128)
//         else {
//             throw TorusUtilError.runtime("invalid oauthkey")

//         }
        
// //        let (pubKeyX, pubKeyY) = try getPublicKeyPointFromAddress(address: oauthPubKey)

//         let pubKeyX = String(oauthPubKey.prefix(64))
//         let pubKeyY = String(oauthPubKey.suffix(64))

//         let poly = try generateRandomPolynomial(degree: degree, secret: oauthKey)
//         let shares = poly.generateShares(shareIndexes: nodeIndexesBigInt)

//         let nonceParams = try generateNonceMetadataParams(message: "getOrSetNonce", privateKey: oauthKey, nonce: randomNonce)

        
//         var nonceData = ""
//         // Create a JSON encoder
//         let encoder = JSONEncoder()
        
//         // Set the output formatting if needed
//         encoder.outputFormatting = .prettyPrinted
        
//         // Convert the SetNonceData to JSON data
//         let jsonData = try encoder.encode(nonceParams.set_data)
        
//         // Convert the JSON data to a string
//         let jsonString = String(data: jsonData, encoding: .utf8)!
//         // Base64 encode the JSON string
//         let base64EncodedString = Data(jsonString.utf8).base64EncodedString()
//         nonceData = base64EncodedString
            

//         var sharesData: [ImportedShare] = []
        
//         var encShares: [Ecies] = []
//         var encErrors: [Error] = []
        
//         for (i, _) in nodeIndexesBigInt.enumerated() {
//             let shareIdx = String(nodeIndexesBigInt[i], radix: 16)
//             print("idx",shareIdx)
//             let share = shares[shareIdx]
//             let nodePubKey = "04" + nodePubKeys[i].X.addLeading0sForLength64() + nodePubKeys[i].Y.addLeading0sForLength64()

//             let shareData = share?.share
//             let shareString = String(shareData!, radix: 16)

//             if shareData == nil {
//                 continue
//             }
//             do {
//                 // TODO: we need encrypt logic here
//                 let encShareData = try encrypt(publicKey: nodePubKey, msg: shareString)
//                 encShares.append(encShareData)
//             } catch {
//                 encErrors.append(error)
//             }
            
//         }
        
//         for (i, _) in nodeIndexesBigInt.enumerated() {
//             let shareJson = shares[String(nodeIndexesBigInt[i], radix: 16)]
//             let encParams = encShares[i]
//             let encParamsMetadata = encParamsBufToHex(encParams: encParams)
//             let shareData = ImportedShare(
//                 pubKeyX: pubKeyX,
//                 pubKeyY: pubKeyY,
//                 encryptedShare: encParamsMetadata.ciphertext!,
//                 encryptedShareMetadata: encParamsMetadata,
//                 nodeIndex: Int(shareJson!.shareIndex),
//                 keyType: "secp256k1",
//                 nonceData: nonceData,
//                 nonceSignature: nonceParams.signature
//             )
//             sharesData.append(shareData)
//         }
        
        
//         return try await retrieveOrImportShare(
//             allowHost: self.allowHost,
//             network: self.network,
//             clientId: self.clientId,
//             endpoints: endpoints,
//             verifier: verifier,
//             verifierParams: verifierParams,
//             idToken: idToken,
//             importedShares: sharesData,
//             extraParams: extraParams
//         )
//     }
    

    
    // MARK: - utils

    func combinations<T>(elements: ArraySlice<T>, k: Int) -> [[T]] {
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

    func combinations<T>(elements: [T], k: Int) -> [[T]] {
        return combinations(elements: ArraySlice(elements), k: k)
    }

    func makeUrlRequest(url: String, httpMethod: HTTPMethod = .post) throws -> URLRequest {
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

    func  thresholdSame<T: Hashable>(arr: [T], threshold: Int) -> T? {
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



    // MARK: - metadata API
    func getMetadata(dictionary: [String: String]) async throws -> BigUInt {
        let encoded: Data?
        do {
            encoded = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            throw error
        }
        
        guard let encodedUnwrapped = encoded else {
            throw TorusUtilError.runtime("Unable to serialize dictionary into JSON. \(dictionary)")
        }
        var request = try! makeUrlRequest(url: "\(metadataHost)/get")
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

    // MARK: - importShare
    
    func importShare(endpoints: [String], nodeSigs: [CommitmentRequestResponse], verifier: String, verifierParams: VerifierParams, idToken: String, importedShares: [ImportedShare], extraParams: [String: Any] = [:]) async throws -> [URLRequest] {
        let session = createURLSession()
        let threshold = Int(endpoints.count / 2) + 1
        var rpcdata: Data = Data()
        var rpcArray = [Data]()
        
        // put rpc data into array
        for importedShare in importedShares {
            do {
                let loadedStrings = extraParams
                let valueDict = ["idtoken": idToken,
                                 "nodesignatures": nodeSigs,
                                 "verifieridentifier": verifier,
                                 "pub_key_x": importedShare.pubKeyX,
                                 "pub_key_y": importedShare.pubKeyY,
                                 "encrypted_share": importedShare.encryptedShare,
                                 "encrypted_share_metadata": importedShare.encryptedShareMetadata,
                                 "node_index": importedShare.nodeIndex,
                                 "key_type": importedShare.keyType,
                                 "nonce_data": importedShare.nonceData,
                                 "nonce_signature": importedShare.nonceSignature,
                                 "verifier_id": verifierParams.verifier_id,
                                 "extended_verifier_id": verifierParams.extended_verifier_id,
                         
                ] as [String: Codable]
                let keepingCurrent = loadedStrings.merging(valueDict) { current, _ in current }
                let finalItem = keepingCurrent.merging(verifierParams.additionalParams) { current, _ in current }
                
                let params = ["encrypted": "yes",
                              "use_temp": true,
                              "one_key_flow": true,
                              "item": AnyCodable([finalItem])
                ] as [String: AnyCodable]
                
                print("params",params)
                // TODO: Look into hetrogeneous array encoding
                let dataForRequest = ["jsonrpc": "2.0",
                                      "id": 10,
                                      "method": AnyCodable(JRPC_METHODS.IMPORT_SHARE),
                                      "params": AnyCodable(params)
                ] as [String: AnyCodable]
                rpcdata = try JSONEncoder().encode(dataForRequest)
                rpcArray.append(rpcdata)
            } catch {
                os_log("import share - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            }
        }
        
        var requestArray = [URLRequest]()


        for i in 0..<importedShares.count {
            do {
                var request = try makeUrlRequest(url: endpoints[i])
                request.httpBody = rpcArray[i]
                requestArray.append(request)
            } catch {
                throw error
            }
            
        }
        
        return requestArray
       
    }
    
    // MARK: - getShareOrKeyAssign
    
    func getShareOrKeyAssign(endpoints: [String], nodeSigs: [CommitmentRequestResponse], verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String: Codable] = [:]) async throws -> [URLRequest] {
        let session = createURLSession()
        let threshold = Int(endpoints.count / 2) + 1
        var rpcdata: Data = Data()
        
        let loadedStrings = extraParams
        let valueDict = ["idtoken": idToken,
                         "nodesignatures": nodeSigs,
                         "verifieridentifier": verifier,
                         "verifier_id": verifierParams.verifier_id,
                         "extended_verifier_id": verifierParams.extended_verifier_id,
                         "test" :true
                 
        ] as [String: Codable]
                
        let keepingCurrent = loadedStrings.merging(valueDict) { current, _ in current }
        let finalItem = keepingCurrent.merging(verifierParams.additionalParams) { current, _ in current }
        
        let params =  ["encrypted": "yes",
                       "use_temp": true,
                       "one_key_flow": true,
                    "item": AnyCodable([finalItem])
        ] as [String: AnyCodable]
        
        let dataForRequest = ["jsonrpc": "2.0",
                              "id": 10,
                              "method": AnyCodable(JRPC_METHODS.GET_SHARE_OR_KEY_ASSIGN),
                              "params": AnyCodable(params)
                            ] as [String: AnyCodable]
        
        do {
            rpcdata = try JSONEncoder().encode(dataForRequest)
        } catch {
            os_log("import share - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }

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


    // MARK: - retreiveDecryptAndReconstuct

//    func retrieveDecryptAndReconstruct(endpoints: [String], extraParams: Data, verifier: String, tokenCommitment: String, nodeSignatures: [CommitmentRequestResponse], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) async throws -> (String, String, String) {
//        // Rebuild extraParams
//        let session = createURLSession()
//        let threshold = Int(endpoints.count / 2) + 1
//        var rpcdata: Data = Data()
//        do {
//            if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(extraParams) as? [String: Any] {
//                let value = ["verifieridentifier": verifier, "verifier_id": verifierId, "nodesignatures": nodeSignatures.tostringDict(), "idtoken": tokenCommitment] as [String: Any]
//                let keepingCurrent = loadedStrings.merging(value) { current, _ in current }
//                // TODO: Look into hetrogeneous array encoding
//                let dataForRequest = ["jsonrpc": "2.0",
//                                      "id": 10,
//                                      "method": "ShareRequest",
//                                      "params": ["encrypted": "yes",
//                                                 "item": [keepingCurrent]] as [String: Any]] as [String: Any]
//                rpcdata = try JSONSerialization.data(withJSONObject: dataForRequest)
//            }
//        } catch {
//            os_log("retrieveDecryptAndReconstruct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
//        }
//
//        var shareResponses = [[String: String]?].init(repeating: nil, count: endpoints.count)
//        var resultArray = [Int: RetrieveDecryptAndReconstuctResponse]()
//        var errorStack = [Error]()
//        var requestArr = [URLRequest]()
//        for (_, el) in endpoints.enumerated() {
//            do {
//                var rq = try makeUrlRequest(url: el)
//                rq.httpBody = rpcdata
//                requestArr.append(rq)
//            } catch {
//                throw error
//            }
//        }
//        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: {[unowned self] group in
//            for (i, rq) in requestArr.enumerated() {
//                group.addTask {
//                    do {
//                        let val = try await session.data(for: rq)
//                        return .success(.init(data: val.0, urlResponse: val.1, index: i))
//                    } catch {
//                        return .failure(error)
//                    }
//                }
//            }
//
//            for try await val in group {
//                do {
//                    try Task.checkCancellation()
//                    switch val {
//                    case .success(let model):
//                        let _data = model.data
//                        let i = model.index
//                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: _data)
//                        if decoded.error != nil {
//                            throw TorusUtilError.decodingFailed(decoded.error?.data)
//                        }
//                        os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")
//
//                        guard
//                            let decodedResult = decoded.result as? [String: Any],
//                            let keyObj = decodedResult["keys"] as? [[String: Any]]
//                        else { throw TorusUtilError.decodingFailed("keys not found in result \(decoded)") }
//
//                        // Due to multiple keyAssign
//                        if let first = keyObj.first {
//                            guard
//                                let metadata = first["Metadata"] as? [String: String],
//                                let share = first["Share"] as? String,
//                                let publicKey = first["PublicKey"] as? [String: String],
//                                let iv = metadata["iv"],
//                                let ephemPublicKey = metadata["ephemPublicKey"],
//                                let pubKeyX = publicKey["X"],
//                                let pubKeyY = publicKey["Y"]
//                            else {
//                                throw TorusUtilError.decodingFailed("\(first)")
//                            }
//                            shareResponses[i] = publicKey // For threshold
//                            let model = RetrieveDecryptAndReconstuctResponse(iv: iv, ephemPublicKey: ephemPublicKey, share: share, pubKeyX: pubKeyX, pubKeyY: pubKeyY)
//                            resultArray[i] = model
//                        }
//
//                        let lookupShares = shareResponses.filter { $0 != nil } // Nonnil elements
//
//                        // Comparing dictionaries, so the order of keys doesn't matter
//
//                        let keyResult = thresholdSame(arr: lookupShares.map { $0 }, threshold: threshold) // Check if threshold is satisfied
//                        var data: [Int: String] = [:]
//                        if keyResult != nil {
//                            os_log("retreiveIndividualNodeShares - result: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, resultArray)
//                            data = try decryptIndividualShares(shares: resultArray, privateKey: privateKey)
//                        } else {
//                            throw TorusUtilError.empty
//                        }
//                        os_log("retrieveDecryptAndReconstuct - data after decryptIndividualShares: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data)
//                        let filteredData = data.filter { $0.value != TorusUtilError.decodingFailed(nil).debugDescription }
//                        if filteredData.count < threshold { throw TorusUtilError.thresholdError }
//                        let thresholdLagrangeInterpolationData = try thresholdLagrangeInterpolation(data: filteredData, endpoints: endpoints, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY)
//                        session.invalidateAndCancel()
//                        return thresholdLagrangeInterpolationData
//                    case .failure(let error):
//                        throw error
//                    }
//                } catch {
//                    errorStack.append(error)
//                    let nsErr = error as NSError
//                    let userInfo = nsErr.userInfo as [String: Any]
//                    if error as? TorusUtilError == .timeout {
//                        group.cancelAll()
//                        session.invalidateAndCancel()
//                        throw error
//                    }
//                    if nsErr.code == -1003 {
//                        // In case node is offline
//                        os_log("retrieveDecryptAndReconstuct: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)
//                    } else if let err = (error as? TorusUtilError) {
//                        if err == TorusUtilError.thresholdError {
//                            os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
//                        }
//                    } else {
//                        os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
//                    }
//                }
//            }
//            throw TorusUtilError.runtime("retrieveDecryptAndReconstuct func failed")
//        })
//
//    }
    
    // MARK: - retrieveOrImportShare
    
    func retrieveOrImportShare(
        legacyMetadataHost: String,
        allowHost: String,
        enableOneKey: Bool,
        network: TorusNetwork,
        clientId: String,
        endpoints: [String],
        verifier: String,
        verifierParams: VerifierParams,
        idToken: String,
        importedShares: [ImportedShare]? = nil,
        extraParams: [String: Any] = [:]
    ) async throws -> TorusKey {
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        guard
            let sessionAuthKey = generatePrivateKeyData()?.toHexString(),
            let publicKey = SECP256K1.privateToPublic(privateKey: Data(hex:sessionAuthKey))?.subdata(in: 1 ..< 65)
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
        
        var isImportShareReq = false
        
        if let importedShares = importedShares, !importedShares.isEmpty {
            if importedShares.count != endpoints.count {
                throw TorusUtilError.runtime("Invalid import share length.")
            }
            isImportShareReq = true
        }

        let nodeSigs = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
        os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, nodeSigs)
        var promiseArrRequest = [URLRequest]()
        
        // TODO: make sure we have only complete requests in promiseArrRequest?
        if (isImportShareReq) {
            promiseArrRequest = try await importShare(endpoints: endpoints, nodeSigs: nodeSigs, verifier: verifier, verifierParams: verifierParams, idToken: idToken, importedShares: importedShares!)
        } else {
            promiseArrRequest = try await getShareOrKeyAssign(endpoints: endpoints, nodeSigs: nodeSigs, verifier: verifier, verifierParams: verifierParams, idToken: idToken)
        }
        
        
        var thresholdNonceData : GetOrSetNonceResult?
        var pubkeyArr = [KeyAssignment.PublicKey]()
        var completeShareRequestResponseArr = [ShareRequestResult]()
        // step 2.
        let thresholdPublicKey : KeyAssignment.PublicKey = try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: { group in

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
            var success = 0
            var failure = 0
            for try await val in group {
                do {
                    switch val {
                        
                    case.success(let model):
                        let data = model.data
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        os_log("import share - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")
                        
                        if decoded.error != nil {
                            os_log("import share - decode error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                            throw TorusUtilError.runtime(decoded.error?.message ?? "")
                        }
                        
                        // Ensure that we don't add bad data to result arrays.
                        guard
                            let decodedResult = decoded.result as? ShareRequestResult
                        else { throw TorusUtilError.decodingFailed("ShareReqeust error decoding error : \(decoded), can't decode into shareRequestResult") }
                        
                        completeShareRequestResponseArr.append(decodedResult)
                        let keyObj = decodedResult.keys
                        if let first = keyObj.first {

                            let pubkey = first.publicKey
                            let pubNonce = first.nonceData?.pubNonce?.x
                            let nonceData = first.nonceData
                            
                            pubkeyArr.append(pubkey)
                            if thresholdNonceData == nil && verifierParams.extended_verifier_id == nil {
                                if pubNonce != nil {
                                    thresholdNonceData = nonceData
                                }
                            }
                            //                            pubkeyArr.append(pubkey)
                            guard let result = thresholdSame(arr: pubkeyArr, threshold: threshold)
                            else {
                                
                                os_log("invalid result from nodes, threshold number of public key results are not matching", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug)
                                throw NSError()
                            }
                            return result
//                            if let result1 == result {
//                                return result1
//                            } else {
//                                os_log("invalid result from nodes, threshold number of public key results are not matching", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug)
//                            }
                            
                            // if both thresholdNonceData and extended_verifier_id are not available
                            // then we need to throw otherwise the address would be incorrect.
                            if result == nil && verifierParams.extended_verifier_id == nil {
                                os_log("invalid metadata result from nodes, nonce metadata is empty for verifier: %@ and verifierId: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, verifier, verifierParams.verifier_id)
                            }
                        }
                        
                    case.failure(let error):
                        throw error
                    }
                } catch {
                    
                        os_log("importshare - commitment request error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error))
                }
            }
            throw TorusUtilError.commitmentRequestFailed
        })
        
        // optimistically run lagrange interpolation once threshold number of shares have been received
        // this is matched against the user public key to ensure that shares are consistent
        // Note: no need of thresholdMetadataNonce for extended_verifier_id key
        if promiseArrRequest.count >= threshold {
            
            if thresholdPublicKey != nil && (thresholdNonceData != nil || verifierParams.extended_verifier_id != nil) {
                
                // Code block to execute if all conditions are true
                var sharePromises = [String]()
                var sessionTokenSigPromises = [String?]()
                var sessionTokenPromises = [String?]()
                var nodeIndexes = [Int]()
                var sessionTokenData = [SessionToken?]()
                
                
                for currentShareResponse in completeShareRequestResponseArr {
                    let sessionTokens = currentShareResponse.sessionTokens
                    let sessionTokenMetadata = currentShareResponse.sessionTokenMetadata
                    let sessionTokenSigs = currentShareResponse.sessionTokenSigs
                    let sessionTokenSigMetadata = currentShareResponse.sessionTokenSigMetadata
                    let keys = currentShareResponse.keys
                    
                    if sessionTokenSigs.count > 0 {
                        // decrypt sessionSig if enc metadata is sent
                        if (sessionTokenSigMetadata.first?.ephemPublicKey != nil) {
                            sessionTokenSigPromises.append(try? decryptNodeData(eciesData: sessionTokenSigMetadata[0], ciphertextHex: sessionTokenSigs[0], privKey: sessionAuthKey))
                        } else {
                            sessionTokenSigPromises.append(sessionTokenSigs[0])
                        }
                    } else {
                        sessionTokenSigPromises.append(nil)
                    }
                    
                    if sessionTokens.count > 0 {
                        if (sessionTokenMetadata.first?.ephemPublicKey != nil) {
                            sessionTokenPromises.append(try? decryptNodeData(eciesData: sessionTokenMetadata[0], ciphertextHex: sessionTokens[0], privKey: sessionAuthKey))
                        } else {
                            sessionTokenSigPromises.append(sessionTokenSigs[0])
                        }
                    } else {
                        sessionTokenSigPromises.append(nil)
                    }
                    
                    if keys.count > 0 {
                        let latestKey = currentShareResponse.keys[0]
                        nodeIndexes.append(Int(latestKey.nodeIndex))
                        
                        if latestKey.shareMetadata != nil {
                            let data = Data(base64Encoded: latestKey.share, options: [] )!
                            let binaryString = String(data: data, encoding: .ascii) ?? ""
                            let paddedBinaryString = binaryString.padding(toLength: 64, withPad: "0", startingAt: 0)

                            sharePromises.append(try decryptNodeData(eciesData: latestKey.shareMetadata, ciphertextHex: paddedBinaryString, privKey: sessionAuthKey).padLeft(padChar: "0", count: 64))
                        }
                    } else {
//                        nodeIndexes.append(nil)
//                        sharePromises.append(nil)
                    }
                    
                }
                var allPromises = sharePromises + sessionTokenSigPromises + sessionTokenPromises
                
                let validTokens = sessionTokenPromises.filter { sig in
                    if let _ = sig {
                        return true
                    }
                    return false
                }
                
                if verifierParams.extended_verifier_id == nil && validTokens.count < threshold {
                    os_log("Insufficient number of session tokens from nodes, required: %@, found: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, threshold, validTokens.count)
                    throw TorusUtilError.apiRequestFailed
                }

                for (index, x) in sessionTokenPromises.enumerated() {
                    if x == nil {
                        sessionTokenData.append(nil)
                    } else {
                        let token = x!
                        let signature = sessionTokenSigPromises[index]//.toHexString()
                        let nodePubX = completeShareRequestResponseArr[index].nodePubX
                        let nodePubY = completeShareRequestResponseArr[index].nodePubY

                        sessionTokenData.append(SessionToken(token: token, signature: signature!, node_pubx: nodePubX, node_puby: nodePubY))
                    }
                }
                let decryptedShares = sharePromises.enumerated().reduce(into: [ Int : String ]()) { acc, current in
                    let (index, curr) = current
                    acc[nodeIndexes[index]] = curr
                }
                
                // run lagrange interpolation on all subsets, faster in the optimistic scenario than berlekamp-welch due to early exit
                let allCombis = kCombinations(s: decryptedShares.count, k: threshold)
                var returnedKey: String? = nil

                for j in 0..<allCombis.count {
                    let currentCombi = allCombis[j]
                    let totalShare = decryptedShares.count
                    let currentCombiShares = decryptedShares.enumerated().reduce(into: [ Int : String ]()) { acc, current in
                        let (index, curr) = current
                        if (currentCombi.contains(index)) {
                            acc[curr.key] = curr.value
                        }
                    }
                    let derivedPrivateKey = try lagrangeInterpolation(shares: currentCombiShares, offset: 0)
                    let derivedPrivateKeyHex = derivedPrivateKey
                
                    guard let derivedPrivateKeyData = Data(hexString: derivedPrivateKeyHex) else {
                        continue
                    }
                    let decryptedPubKey = SECP256K1.privateToPublic(privateKey: Data(hex: derivedPrivateKey) )?.toHexString()
                    
                    let decryptedPubKeyX = String(decryptedPubKey!.prefix(64))
                    let decryptedPubKeyY = String(decryptedPubKey!.suffix(64))
                    let decryptedPubKeyXBigInt = BigUInt(decryptedPubKeyX, radix: 16)!
                    let decryptedPubKeyYBigInt = BigUInt(decryptedPubKeyY, radix: 16)!
                    let thresholdPublicKeyXBigInt = BigUInt(thresholdPublicKey.X, radix: 16)!
                    let thresholdPublicKeyYBigInt = BigUInt(thresholdPublicKey.Y, radix: 16)!
                    returnedKey = derivedPrivateKey
                    if decryptedPubKeyXBigInt == thresholdPublicKeyXBigInt && decryptedPubKeyYBigInt == thresholdPublicKeyYBigInt {
                        returnedKey = derivedPrivateKey
                        break
                    }
                }
                guard let oAuthKey = returnedKey else {
                    throw TorusUtilError.privateKeyDeriveFailed
                }
                
                let oAuthKeyBigInt = BigInt(oAuthKey , radix: 16)!
                
                guard let derivedPrivateKeyData = Data(hexString: oAuthKey) else {
                    throw TorusUtilError.privateKeyDeriveFailed
                }
                
                let oAuthPubKey = SECP256K1.privateToPublic(privateKey: derivedPrivateKeyData)?.toHexString()
                let oauthPubKeyX = String(oAuthPubKey!.suffix(128).prefix(64))
                let oauthPubKeyY = String(oAuthPubKey!.suffix(64))
                
                let metadataNonce = BigInt(thresholdNonceData?.nonce ?? "0", radix: 16) ?? BigInt(0)
                let privateKeyWithNonce = (oAuthKeyBigInt + metadataNonce) % modulusValue

                var pubKeyNonceResult: PubNonce?
                var typeOfUser: UserType = .v1
                
                var modifiedPubKey = "04" + oauthPubKeyX.addLeading0sForLength64() + oauthPubKeyY.addLeading0sForLength64()
                
                if verifierParams.extended_verifier_id != nil {
                    typeOfUser = .v2
                    // For TSS key, no need to add pub nonce
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                    //                } else if (LEGACY_NETWORKS_ROUTE_MAP[self.network] != nil) {
                    //
                    //                }
                }
                else {
                    typeOfUser = .v2
                    let pubNonceX = thresholdNonceData!.pubNonce!.x
                    let pubNonceY = thresholdNonceData!.pubNonce!.y
                    let pubkey2 = "04" + pubNonceX.addLeading0sForLength64() + pubNonceY.addLeading0sForLength64()
                    let combined = combinePublicKeys(keys: [modifiedPubKey, pubkey2], compressed: false)
                    modifiedPubKey = combined
                    pubKeyNonceResult = .init(x: pubNonceX, y: pubNonceY)
                }


                
                let (finalPubX , finalPubY) = try getPublicKeyPointFromAddress(address: modifiedPubKey)
                let (oAuthKeyX, oAuthKeyY) = try getPublicKeyPointFromAddress(address: oAuthPubKey!)
                let oAuthKeyAddress = generateAddressFromPrivKey(privateKey: oAuthKey)
                
                // deriving address from pub key coz pubkey is always available
                // but finalPrivKey won't be available for  v2 user upgraded to 2/n
                let finalEvmAddress = generateAddressFromPubKey(publicKeyX: finalPubX, publicKeyY: finalPubY)
                var finalPrivKey = ""
                
                if typeOfUser == .v1 || (typeOfUser == .v2 && metadataNonce > BigInt(0)) {
                    let privateKeyWithNonce = (BigInt(oAuthKey, radix: 16) ?? BigInt(0)) + metadataNonce
                    let finalPrivKey = privateKeyWithNonce.serialize().toHexString().addLeading0sForLength64()
                }
    
                    
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
                        X: finalPubX,
                        Y: finalPubY,
                        privKey: finalPrivKey
                    ),
                    oAuthKeyData: .init(
                        evmAddress: oAuthKeyAddress,
                        X: oAuthKeyX,
                        Y: oAuthKeyY,
                        privKey: oAuthKey.data(using: .utf8)!.toHexString().addLeading0sForLength64()
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

//                return RetrieveSharesResponse(
//                    ethAddress: generateAddressFromPubKey(publicKeyX: finalPubX.addLeading0sForLength64(), publicKeyY: finalPubY.addLeading0sForLength64()), // this address should be used only if user hasn't updated to 2/n
//                    privKey: String(privateKeyWithNonce, radix: 16).leftPadding(toLength: 64, withPad: "0"), // Caution: final x and y wont be derivable from this key once user upgrades to 2/n
//                    sessionTokenData: sessionTokenData,
//                    X: finalPubX, // this is final pub x of user before and after updating to 2/n
//                    Y: finalPubY, // this is final pub y of user before and after updating to 2/n
//                    metadataNonce: metadataNonce,
//                    postboxPubKeyX: oauthPubKeyX,
//                    postboxPubKeyY: oauthPubKeyY,
//                    sessionAuthKey: sessionAuthKey, //.map { String(format: "%02x", $0) }.joined().padding(toLength: 64, withPad: "0", startingAt: 0),
//                    nodeIndexes: nodeIndexes
//                )

            }
            
        }
        throw TorusUtilError.retrieveOrImportShareError
    }

    // MARK: - commitment request

    func commitmentRequest(endpoints: [String], verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) async throws -> [CommitmentRequestResponse] {
        let session = createURLSession()
        let threshold = Int(endpoints.count / 4) * 3 + 1
        let encoder = JSONEncoder()
        var failedLookUpCount = 0
        let jsonRPCRequest = JSONRPCrequest(
            method: "CommitmentRequest",
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
                    case.success(let model):
                        let data = model.data
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        os_log("commitmentRequest - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")

                        if decoded.error != nil {
                            os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                            throw TorusUtilError.runtime(decoded.error?.message ?? "")
                        }

                        // Ensure that we don't add bad data to result arrays.
                        guard
                            let response = decoded.result as? CommitmentRequestResponse
                        else {
                            throw TorusUtilError.decodingFailed("\(decoded.result) is not a CommitmentRequestResponse")
                        }

                        // Check if k+t responses are back
                        let val = CommitmentRequestResponse(data: response.data, nodepubx: response.nodepubx, nodepuby: response.nodepuby, signature: response.signature)
                        nodeSignatures.append(val)
                        if nodeSignatures.count >= threshold {
                            os_log("commitmentRequest - nodeSignatures: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, nodeSignatures)
                            session.invalidateAndCancel()
                            return nodeSignatures
                        }
                    case.failure(let error):
                        throw error
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
    
    func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
        guard let params = params, let message = params["message"] as? String else {
            return BigUInt(0)
        }
        return BigUInt(message, radix: 16)!
    }
    
    func decryptNodeData(eciesData: EciesHex, ciphertextHex: String, privKey: String) throws -> String {

        let eciesOpts = ECIES(
            iv: eciesData.iv,
            ephemPublicKey: eciesData.ephemPublicKey,
            ciphertext: ciphertextHex,
            mac: eciesData.mac
        )
        
        let decryptedSigBuffer = try decrypt(privateKey: privKey, opts: eciesOpts).toHexString()
        return decryptedSigBuffer
    }

   
    func encryptData(privkeyHex: String, _ dataToEncrypt: String) throws -> String {
        guard let pubKey = SECP256K1.privateToPublic(privateKey: privkeyHex.hexa.data)?.web3.hexString.web3.noHexPrefix else {
            throw TorusUtilError.runtime("Invalid private key hex")
        }
        let encParams = try encrypt(publicKey: pubKey, msg: dataToEncrypt, opts: nil)
        let data = try JSONEncoder().encode(encParams)
        guard let string = String(data: data, encoding: .utf8) else { throw TorusUtilError.runtime("Invalid String from enc Params") }
        return string
    }
    
    private func encrypt(publicKey: String, msg: String, opts: Ecies? = nil) throws -> Ecies {
         guard let ephemPrivateKey = SECP256K1.generatePrivateKey(), let ephemPublicKey = SECP256K1.privateToPublic(privateKey: ephemPrivateKey)
         else {
             throw TorusUtilError.runtime("Private key generation failed")
         }
         let ephermalPublicKey = publicKey.strip04Prefix()
         let ephermalPublicKeyBytes = ephermalPublicKey.hexa
         var ephermOne = ephermalPublicKeyBytes.prefix(32)
         var ephermTwo = ephermalPublicKeyBytes.suffix(32)
         ephermOne.reverse(); ephermTwo.reverse()
         ephermOne.append(contentsOf: ephermTwo)
         let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
         guard
             // Calculate g^a^b, i.e., Shared Key
             //  let data = inprivateKey
             let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: ephemPrivateKey)
         else {
             throw TorusUtilError.runtime("ECDH error")
         }

         let sharedSecretData = sharedSecret.data
         let sharedSecretPrefix = Array(tupleToArray(sharedSecretData).prefix(32))
         let reversedSharedSecret = sharedSecretPrefix.uint8Reverse()
         let hash = SHA2(variant: .sha512).calculate(for: Array(reversedSharedSecret))
         let iv: [UInt8] = (opts?.iv ?? SECP256K1.randomBytes(length: 16)?.toHexString())?.hexa ?? []
         let encryptionKey = Array(hash.prefix(32))
         let macKey = Array(hash.suffix(32))
         do {
             // AES-CBCblock-256
             let aes = try AES(key: encryptionKey, blockMode: CBC(iv: iv), padding: .pkcs7)
             let encrypt = try aes.encrypt(msg.bytes)
             let data = Data(encrypt)
             let ciphertext = data
             var dataToMac: [UInt8] = iv
             dataToMac.append(contentsOf: [UInt8](ephemPublicKey.data))
             dataToMac.append(contentsOf: [UInt8](ciphertext.data))
             let mac = try? HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(dataToMac)
             return .init(iv: iv.toHexString(), ephemPublicKey: ephemPublicKey.toHexString(),
             ciphertext: ciphertext.toHexString(), mac: mac?.toHexString() ?? "")
         } catch let err {
             throw err
         }
     }
     
//    // MARK: decrypt opts
//    // TODO: check toHexString() is right way or not
//    public func decryptOpts(privateKey: Data, opts: Ecies, padding: Bool = false) throws -> Data {
//        let k = opts.ephemPublicKey.toHexString()
//        let ephermalPublicKey = k.strip04Prefix()
//        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
//        var ephermOne = ephermalPublicKeyBytes.prefix(32)
//        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
//        // Reverse because of C endian array storage
//        ephermOne.reverse(); ephermTwo.reverse()
//        ephermOne.append(contentsOf: ephermTwo)
//        let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
//
//        guard
//            // Calculate g^a^b, i.e., Shared Key
//            let data = Data(hexString: privateKey.toHexString()),
//            let secret = ecdh(pubKey: ephemPubKey, privateKey: data)
//        else {
//            throw TorusUtilError.decryptionFailed
//        }
//
//        let secretData = secret.data
//        let secretPrefix = tupleToArray(secretData).prefix(32)
//        let reversedSecret = secretPrefix.reversed()
//
//        let iv = opts.iv.toHexString().hexa
//        let newXValue = reversedSecret.hexa
//        let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
//        let AesEncryptionKey = hash.prefix(64)
//
//        var result: String = ""
//        do {
//            // AES-CBCblock-256
//            let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
//            let decrypt = try aes.decrypt(opts.ciphertext.bytes)
//            result = decrypt.hexa
//        } catch let err {
//            result = TorusUtilError.decodingFailed(err.localizedDescription).debugDescription
//        }
//        return Data(hex: result)
//    }

    // MARK: - decrypt shares

        func decryptIndividualShares(shares: [Int: RetrieveDecryptAndReconstuctResponseModel], privateKey: String) throws -> [Int: String] {
            var result = [Int: String]()

            for (_, el) in shares.enumerated() {
                let nodeIndex = el.key

                let k = el.value.ephemPublicKey
                let ephermalPublicKey = k.strip04Prefix()
                let ephermalPublicKeyBytes = ephermalPublicKey.hexa
                var ephermOne = ephermalPublicKeyBytes.prefix(32)
                var ephermTwo = ephermalPublicKeyBytes.suffix(32)
                // Reverse because of C endian array storage
                ephermOne.reverse(); ephermTwo.reverse()
                ephermOne.append(contentsOf: ephermTwo)
                let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))

                guard
                    // Calculate g^a^b, i.e., Shared Key
                    let data = Data(hexString: privateKey),
                    let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: data)
                else {
                    throw TorusUtilError.decryptionFailed
                }
                let sharedSecretData = sharedSecret.data
                let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
                let reversedSharedSecret = sharedSecretPrefix.reversed()

                guard
                    let share = el.value.share.fromBase64()?.hexa
                else {
                    throw TorusUtilError.decryptionFailed
                }
                let iv = el.value.iv.hexa
                let newXValue = reversedSharedSecret.hexa
                let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
                let AesEncryptionKey = hash.prefix(64)

                do {
                    // AES-CBCblock-256
                    let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
                    let decrypt = try aes.decrypt(share)
                    result[nodeIndex] = decrypt.hexa
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

    func thresholdLagrangeInterpolation(data filteredData: [Int: String], endpoints: [String], lookupPubkeyX: String, lookupPubkeyY: String) throws -> (String, String, String) {
        // all possible combinations of share indexes to interpolate
        let shareCombinations = combinations(elements: Array(filteredData.keys), k: Int(endpoints.count / 2) + 1)
        for shareIndexSet in shareCombinations {
            var sharesToInterpolate: [Int: String] = [:]
            shareIndexSet.forEach { sharesToInterpolate[$0] = filteredData[$0] }
            do {
                let data = try lagrangeInterpolation(shares: sharesToInterpolate)
                // Split key in 2 parts, X and Y

                guard let finalPrivateKey = data.web3.hexData, let publicKey = SECP256K1.privateToPublic(privateKey: finalPrivateKey)?.subdata(in: 1 ..< 65) else {
                    throw TorusUtilError.decodingFailed("\(data)")
                }
                let paddedPubKey = publicKey.toHexString().padLeft(padChar: "0", count: 128)
                let pubKeyX = String(paddedPubKey.prefix(paddedPubKey.count / 2))
                let pubKeyY = String(paddedPubKey.suffix(paddedPubKey.count / 2))
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

    func lagrangeInterpolation(shares: [Int: String], offset: Int = 1) throws -> String {
        let secp256k1N = modulusValue

        // Convert shares to BigInt(Shares)
        var shareList = [BigInt: BigInt]()
        _ = shares.map { shareList[BigInt($0.key + offset)] = BigInt($0.value, radix: 16) }
        os_log("lagrangeInterpolation: %@ %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, shares, shareList)

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
    
    func getPubKeyOrKeyAssign(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId: String? = nil) async throws -> KeyLookupResult {
        // Encode data
        let encoder = JSONEncoder()
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        var failedLookupCount = 0
        let methodName = JRPC_METHODS.GET_OR_SET_KEY
        
        let params = GetPublicAddressOrKeyAssignParams(verifier: verifier, verifier_id: verifierId, extended_verifier_id: extendedVerifierId, one_key_flow: false, fetch_node_index: false )

        let jsonRPCRequest = JSONRPCrequest(
            method: methodName,
            params: params
        )
        
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
            os_log("%@: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, methodName, error.localizedDescription)
            throw error
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
        var keyArray: [VerifierLookupResponse] = [];
        
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
            
            for try await val in group {
                
                do {
                    switch val {
                    case .success(let model):
                        // print( try JSONSerialization.jsonObject(with: model.data) )
                        let data = model.data
                        do {
                            
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                            let result = decoded.result as? VerifierLookupResponse
                            
                            if let _ = decoded.error {
                                let error = KeyLookupError.createErrorFromString(errorString:  "")
                                throw error
                            } else {
                                if let decodedResult = result  {
                                    keyArray.append(decodedResult)
                                    if let k = decodedResult.keys,
                                       let keys = k.first {
                                        let model = KeyLookupResponse(pubKeyX: keys.pub_key_X, pubKeyY: keys.pub_key_Y, address: keys.address)
                                        
                                        resultArray.append(model)
                                        if let nonceData = keys.nonce_data {
                                            if nonceData.pubNonce != nil {
                                                if (nonceResult == nil ) {
                                                    nonceResult = keys.nonce_data
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            let keyResult = thresholdSame(arr: resultArray, threshold: threshold) // Check if threshold is satisfied
                            print("result array", resultArray)
                            if (nonceResult != nil || extendedVerifierId != nil) {
                                if let keyResult = keyResult {
                                    os_log("%@: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, methodName, keyResult.description)
                                    session.invalidateAndCancel()
                                    keyArray.forEach( { body in
                                        nodeIndexesArray.append(body.node_index)
                                    })
                                    
                                    return KeyLookupResult( keyResult: keyResult, nodeIndexes: nodeIndexesArray, nonceResult: nonceResult)
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
                    if failedLookupCount > (endpoints.count -  threshold) {
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

    func awaitKeyLookup(endpoints: [String], verifier: String, verifierId: String, timeout: Int = 0) async throws -> KeyLookupResponse {
        let durationInNanoseconds = UInt64(timeout * 1_000_000_000)
        try await Task.sleep(nanoseconds: durationInNanoseconds)
        do {
            return try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        } catch {
            throw error
        }
    }
    
    func awaitLegacyKeyLookup(endpoints: [String], verifier: String, verifierId: String, timeout: Int = 0) async throws -> LegacyKeyLookupResponse {
        let durationInNanoseconds = UInt64(timeout * 1_000_000_000)
        try await Task.sleep(nanoseconds: durationInNanoseconds)
        do {
            return try await legacyKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        } catch {
            throw error
        }
    }
    
    public func legacyKeyLookup(endpoints: [String], verifier: String, verifierId: String) async throws -> LegacyKeyLookupResponse {
            // Enode data
            let encoder = JSONEncoder()
            let session = createURLSession()
            let threshold = (endpoints.count / 2) + 1
            var failedLookupCount = 0
            let jsonRPCRequest = JSONRPCrequest(
                method: "VerifierLookupRequest",
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

            return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: {[unowned self] group in
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
                        case .success(let model):
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
                        if failedLookupCount > (endpoints.count -  threshold) {
                            os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, TorusUtilError.runtime("threshold nodes unavailable").localizedDescription)
                            session.invalidateAndCancel()
                            throw error
                        }
                    }
                }
                throw TorusUtilError.runtime("keyLookup func failed")
            })
        }


    public func keyLookup(endpoints: [String], verifier: String, verifierId: String) async throws -> KeyLookupResponse {
        // Enode data
        let encoder = JSONEncoder()
        let session = createURLSession()
        let threshold = (endpoints.count / 2) + 1
        var failedLookupCount = 0
        let jsonRPCRequest = JSONRPCrequest(
            method: "VerifierLookupRequest",
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

        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse, Error>.self, body: {[unowned self] group in
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
                    case .success(let model):
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
                                    let decodedResult = result as? [String: [[String: String]]],
                                    let k = decodedResult["keys"],
                                    let keys = k.first,
                                    let pubKeyX = keys["pub_key_X"],
                                    let pubKeyY = keys["pub_key_Y"],
                                    let address = keys["address"]
                                else {
                                    throw TorusUtilError.decodingFailed("keys not found in \(result )")
                                }
                                let model = KeyLookupResponse(pubKeyX: pubKeyX, pubKeyY: pubKeyY,  address: address)
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
                    if failedLookupCount > (endpoints.count -  threshold) {
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
    
    public func keyAssign(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, signerHost: String, network: TorusNetwork, firstPoint: Int? = nil, lastPoint: Int? = nil) async throws -> JSONRPCresponse {
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

        let SignerObject = JSONRPCrequest(method: "KeyAssign", params: ["verifier": verifier, "verifier_id": verifierId])
        do {
            let rpcdata = try encoder.encode(SignerObject)
            var request = try! makeUrlRequest(url: signerHost)
            request.addValue(torusNodePubs[nodeNum].getX().lowercased(), forHTTPHeaderField: "pubKeyX")
            request.addValue(torusNodePubs[nodeNum].getY().lowercased(), forHTTPHeaderField: "pubKeyY")
            switch network {
                case .legacy(let network ) : request.addValue(network.path, forHTTPHeaderField: "network")
                case .sapphire(let network ) : request.addValue(network.path, forHTTPHeaderField: "network")
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

    
//    public func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool = false) async throws -> GetUserAndAddress {
//          do {
//              var data: KeyLookupResponse
//              do {
//                  data = try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID)
//              } catch {
//                  if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
//                          do {
//                              _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePub, verifier: verifier, verifierId: verifierID, signerHost: signerHost, network: network)
//                              data = try await awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID, timeout: 1)
//                          } catch {
//                              throw TorusUtilError.configurationError
//                          }
//                  } else {
//                      throw error
//                  }
//              }
//              let pubKeyX = data.pubKeyX
//              let pubKeyY = data.pubKeyY
//              var modifiedPubKey: String = ""
//              var nonce: BigUInt = 0
//              var typeOfUser: TypeOfUser = .v1
//              let localNonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, getOnly: !isNewKey)
//              nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
//              typeOfUser = TypeOfUser(rawValue: localNonceResult.typeOfUser ?? "v1" ) ?? .v1
//              if typeOfUser == .v1 {
//                  modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
//                  let nonce2 = BigInt(nonce).modulus(modulusValue)
//                  if nonce != BigInt(0) {
//                      guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
//                          throw TorusUtilError.decryptionFailed
//                      }
//                      modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
//                  } else {
//                      modifiedPubKey = String(modifiedPubKey.suffix(128))
//                  }
//              } else if typeOfUser == .v2 {
//                  modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
//                  let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
//                  modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
//                  modifiedPubKey = String(modifiedPubKey.suffix(128))
//
//              } else {
//                  throw TorusUtilError.runtime("getOrSetNonce should always return typeOfUser.")
//              }
//              let val: GetUserAndAddress = .init(typeOfUser: typeOfUser, address: publicKeyToAddress(key: modifiedPubKey), x: pubKeyX, y: pubKeyY, pubNonce: localNonceResult.pubNonce, nonceResult: localNonceResult.nonce)
//              return val
//          } catch let error {
//             throw error
//          }
//      }
    // TODO: uncomment this func when start legacy support
//      public func getOrSetNonce(x: String, y: String, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResult {
//          var data: Data
//          let msg = getOnly ? "getNonce" : "getOrSetNonce"
//          do {
//              if privateKey != nil {
//                  let val = try generateNonceMetadataParams(message: msg, privateKey: privateKey!)
//                  data = try JSONEncoder().encode(val)
//              } else {
//                  let dict: [String: Any] = ["pub_key_X": x, "pub_key_Y": y, "set_data": ["data": msg]]
//                  data = try JSONSerialization.data(withJSONObject: dict)
//              }
//              var request = try! makeUrlRequest(url: "\(metadataHost)/get_or_set_nonce")
//              request.httpBody = data
//              let val = try await urlSession.data(for: request)
//              let decoded = try JSONDecoder().decode(GetOrSetNonceResult.self, from: val.0)
//              return decoded
//          } catch let error {
//              throw error
//          }
//      }

    func generateNonceMetadataParams(message: String, privateKey: BigInt, nonce: BigInt?) throws -> NonceMetadataParams {
          do {


              guard let privKeyData = Data(hex: String(privateKey, radix: 16).addLeading0sForLength64()),
                    let publicKey = SECP256K1.privateToPublic(privateKey: privKeyData)?.subdata(in: 1 ..< 65).toHexString().padLeft(padChar: "0", count: 128)
              else {
                  throw TorusUtilError.runtime("invalid priv key")
              }

              let timeStamp = String(BigUInt(serverTimeOffset + Date().timeIntervalSince1970), radix: 16)
              var setData: NonceMetadataParams.SetNonceData = .init(data: message, timestamp: timeStamp)
              if (nonce != nil) {
                  setData.data = String(nonce!, radix: 16).addLeading0sForLength64()
              }
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

    public func publicKeyToAddress(key: Data) -> Data {
        return key.web3.keccak256.suffix(20)
    }

    public func publicKeyToAddress(key: String) -> String {
        return key.web3.keccak256fromHex.suffix(20).toHexString().toChecksumAddress()
    }

    func getPublicKeyPointFromAddress( address: String) throws ->  (String, String) {
        let publicKeyHashData = Data.fromHex(address)?.dropFirst()//.dropLast(4)
        guard publicKeyHashData?.count == 64 else {
            print(publicKeyHashData?.count)
            throw "Invalid address,"
        }
        
        let xCoordinateData = publicKeyHashData?.prefix(32).toHexString()
        let yCoordinateData = publicKeyHashData?.suffix(32).toHexString()
        
        if let x = xCoordinateData, let y = yCoordinateData {
            return (x, y)
        }else {
            throw "invalid address"
        }
    }
    
    func combinePublicKeys(keys: [String], compressed: Bool) -> String {
        let data = keys.map({ Data.fromHex($0)! })
        let added = SECP256K1.combineSerializedPublicKeys(keys: data, outputCompressed: compressed)
        return (added?.toHexString())!
    }
    
    func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }

    public func decrypt(privateKey: String, opts: ECIES) throws -> Data {
        let ephermalPublicKey = opts.ephemPublicKey.strip04Prefix()
        let ephermalPublicKeyBytes = ephermalPublicKey.hexa
        var ephermOne = ephermalPublicKeyBytes.prefix(32)
        var ephermTwo = ephermalPublicKeyBytes.suffix(32)
        ephermOne.reverse(); ephermTwo.reverse()
        ephermOne.append(contentsOf: ephermTwo)
        let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))
        guard
            // Calculate g^a^b, i.e., Shared Key
            let data = Data(hexString: privateKey),
            let sharedSecret = SECP256K1.ecdh(pubKey: ephemPubKey, privateKey: data)
        else {
//            throw SessionManagerError.runtimeError("ECDH Error")
            throw "ECDH Error"
        }
        let sharedSecretData = sharedSecret.data
        let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
        let reversedSharedSecret = sharedSecretPrefix.reversed()
        let iv = opts.iv.hexa
        let newXValue = reversedSharedSecret.hexa
        let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
        let aesEncryptionKey = hash.prefix(64)
        do {
            // AES-CBCblock-256
            let aes = try AES(key: aesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
            let decrypt = try aes.decrypt(opts.ciphertext.hexa)
            let data = Data(decrypt)
            return data


        } catch let err {
            throw err
        }
    }
    
}

extension Array where Element == UInt8 {
    func uint8Reverse() -> Array {
        var revArr = [Element]()
        for arrayIndex in stride(from: self.count - 1, through: 0, by: -1) {
            revArr.append(self[arrayIndex])
        }
        return revArr
    }
}
