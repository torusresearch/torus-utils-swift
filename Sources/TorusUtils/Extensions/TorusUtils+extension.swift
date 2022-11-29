//
//  TorusUtils+extension.swift
//
//
//  Created by Shubham on 25/3/20.
//

import FetchNodeDetails
import Foundation
// #if canImport(PMKFoundation)
//    import PMKFoundation
// #endif
#if canImport(secp256k1)
    import secp256k1
#endif
import BigInt
import CryptoSwift
import OSLog

extension TorusUtils {
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

    func combinations<T>(elements: Array<T>, k: Int) -> [[T]] {
        return combinations(elements: ArraySlice(elements), k: k)
    }

    func makeUrlRequest(url: String) throws -> URLRequest {
        guard
            let url = URL(string: url)
        else {
            throw TorusUtilError.runtime("Invalid Url \(url)")
        }
        var rq = URLRequest(url: url)
        rq.httpMethod = "POST"
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        return rq
    }

    func thresholdSame<T: Hashable>(arr: [T], threshold: Int) -> T? {
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

    // MARK: ECDH - Elliptic curve diffie-hellman

    func ecdh(pubKey: secp256k1_pubkey, privateKey: Data) -> secp256k1_pubkey? {
        var localPubkey = pubKey // Pointer takes a variable
        if privateKey.count != 32 { return nil }
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, let ctx = TorusUtils.context, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = withUnsafeMutablePointer(to: &localPubkey) {
                    secp256k1_ec_pubkey_tweak_mul(ctx, $0, privateKeyPointer)
                }
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return localPubkey
    }

    // MARK: metadata API

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
        var request = try! makeUrlRequest(url: "\(metaDataHost)/get")
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

    // MARK: - retreiveDecryptAndReconstuct

    func retrieveDecryptAndReconstruct(endpoints: Array<String>, extraParams: Data, verifier: String, tokenCommitment: String, nodeSignatures: [[String: String]], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) async throws -> (String, String, String) {
        // Rebuild extraParams
        var rpcdata: Data = Data()
        do {
            if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(extraParams) as? [String: Any] {
                let value = ["verifieridentifier": verifier, "verifier_id": verifierId, "nodesignatures": nodeSignatures, "idtoken": tokenCommitment] as [String: Any]
                let keepingCurrent = loadedStrings.merging(value) { current, _ in current }
                // TODO: Look into hetrogeneous array encoding
                let dataForRequest = ["jsonrpc": "2.0",
                                      "id": 10,
                                      "method": "ShareRequest",
                                      "params": ["encrypted": "yes",
                                                 "item": [keepingCurrent]]] as [String: Any]
                rpcdata = try JSONSerialization.data(withJSONObject: dataForRequest)
            }
        } catch {
            os_log("retrieveDecryptAndReconstruct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }

        var shareResponses = Array<[String: String]?>.init(repeating: nil, count: endpoints.count)
        var resultArray = [Int: [String: String]]()
        var errorStack = [Error]()
        var requestArr = [URLRequest]()
        for (i,el) in endpoints.enumerated(){
            do{
                if i == 0{
                    let rq = URLRequest(url: URL(string:"bfjdbfjdbjfbvj/random")!)
                    requestArr.append(rq)
                }else{
                    var rq = try makeUrlRequest(url: el)
                    rq.httpBody = rpcdata
                    requestArr.append(rq)
                }
            }catch{
                throw error
            }
        }
        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse,Error>.self, body: { group in
            for (i,rq) in requestArr.enumerated() {
                        group.addTask {
                            do{
                                let val = try await self.urlSession.data(for: rq)
                                return .success(.init(data: val.0, urlResponse: val.1, index: i))
                            }
                            catch{
                                return .failure(error)
                            }
                        }
                    }

            for try await val in group{
                do{
                switch val{
                case .success(let model):
                    let _data = model.data
                    let i = model.index
                    let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: _data)
                    if decoded.error != nil {
                        throw TorusUtilError.decodingFailed(decoded.error?.data)
                    }
                    os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")
                    
                    guard
                        let decodedResult = decoded.result as? [String: Any],
                        let keyObj = decodedResult["keys"] as? [[String: Any]]
                    else { throw TorusUtilError.decodingFailed("keys not found in result \(decoded)") }
                    
                    // Due to multiple keyAssign
                    if let first = keyObj.first {
                        guard
                            let metadata = first["Metadata"] as? [String: String],
                            let share = first["Share"] as? String,
                            let publicKey = first["PublicKey"] as? [String: String],
                            let iv = metadata["iv"],
                            let ephemPublicKey = metadata["ephemPublicKey"],
                            let pubKeyX = publicKey["X"],
                            let pubKeyY = publicKey["Y"]
                        else {
                            throw TorusUtilError.decodingFailed("\(first)")
                        }
                        shareResponses[i] = publicKey // For threshold
                        resultArray[i] = [
                            "iv": iv,
                            "ephermalPublicKey": ephemPublicKey,
                            "share": share,
                            "pubKeyX": pubKeyX,
                            "pubKeyY": pubKeyY,
                        ]
                    }
                    
                    let lookupShares = shareResponses.filter { $0 != nil } // Nonnil elements
                    
                    // Comparing dictionaries, so the order of keys doesn't matter
                    let keyResult = thresholdSame(arr: lookupShares.map { $0 }, threshold: Int(endpoints.count / 2) + 1) // Check if threshold is satisfied
                    var data: [Int: String] = [:]
                    if keyResult != nil {
                        os_log("retreiveIndividualNodeShares - result: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, resultArray)
                        data = try decryptIndividualShares(shares: resultArray, privateKey: privateKey)
                    } else {
                        throw TorusUtilError.empty
                    }
                    os_log("retrieveDecryptAndReconstuct - data after decryptIndividualShares: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data)
                    let filteredData = data.filter { $0.value != TorusUtilError.decodingFailed(nil).debugDescription }
                    if filteredData.count < Int(endpoints.count / 2) + 1 { throw TorusUtilError.thresholdError }
                    let thresholdLagrangeInterpolationData = try thresholdLagrangeInterpolation(data: filteredData, endpoints: endpoints, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY)
                    return thresholdLagrangeInterpolationData
                case .failure(let error):
                    throw error
                    }
                }
                // print("index of the request \( val.1)")
                catch {
                    errorStack.append(error)
                    let nsErr = error as NSError
                    let userInfo = nsErr.userInfo as [String: Any]
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
    
    

    // MARK: - commitment request

    func commitmentRequest(endpoints: Array<String>, verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) async throws -> [[String: String]] {
        let encoder = JSONEncoder()
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
        var resultArrayStrings = Array<Any?>.init(repeating: nil, count: endpoints.count)
        var resultArrayObjects = Array<JSONRPCresponse?>.init(repeating: nil, count: endpoints.count)
      
        var requestArr = [URLRequest]()
        var lookupCount = 0
        for (i, el) in endpoints.enumerated() {
            do {
                    var rq = try makeUrlRequest(url: el)
                    rq.httpBody = rpcdata
                    requestArr.append(rq)
            } catch {
                throw error
            }
        }
        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse,Error>.self, body: { group in

          var localLookUpCount = 0
         var passedRequest = 0
          for (i,rq) in requestArr.enumerated(){

              group.addTask {
                  do{
                      let val = try await self.urlSession.data(for: rq)
                      return .success(.init(data: val.0, urlResponse: val.1, index: i))
                  }
                  catch{
                      return .failure(error)
                  }
              }
          }
            for try await val in group{
                do{
                    switch val{
                    case.success(let model):
                        passedRequest += 1
                          print("index of the request \( model.index)")
                        let data = model.data
                        let i = model.index
                        let encoder = JSONEncoder()
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        os_log("commitmentRequest - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")
                        
                        if decoded.error != nil {
                            os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                            throw TorusUtilError.runtime(decoded.error?.message ?? "")
                        }
                        // Check if k+t responses are back
                        resultArrayStrings[i] = String(data: try encoder.encode(decoded), encoding: .utf8)
                        resultArrayObjects[i] = decoded
                        
                        let lookupShares = resultArrayStrings.filter { $0 as? String != nil } // Nonnil elements
                        if lookupShares.count >= Int(endpoints.count / 4) * 3 + 1 {
                            let nodeSignatures = try resultArrayObjects.compactMap { $0 }.map { (a: JSONRPCresponse) throws -> [String: String] in
                                os_log("nodeSignatures - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(a)")
                                guard
                                    let r = a.result as? [String: String]
                                else {
                                    throw TorusUtilError.decodingFailed("\(a.result) not found in \(a)")
                                }
                                return r
                            }
                            os_log("commitmentRequest - nodeSignatures: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, nodeSignatures)
                            return nodeSignatures
                        }
                    case.failure(let error):
                        print(error)
                        throw error
                    }
                }
                catch {
                    print(error)
                    let nsErr = error as NSError
                    let userInfo = nsErr.userInfo as [String: Any]
                    if nsErr.code == -1003 {
                        // In case node is offline
                        os_log("commitmentRequest: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)
                        
                        // Reject if threshold nodes unavailable
                        lookupCount += 1
                        if lookupCount > endpoints.count {
                            throw TorusUtilError.nodesUnavailable
                        }
                    } else {
                        os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    }
                }
            }
            print("\(passedRequest) / \(requestArr.count)")
            throw TorusUtilError.commitmentRequestFailed
              })
    }

    // MARK: - decrypt shares

    func decryptIndividualShares(shares: [Int: [String: String]], privateKey: String) throws -> [Int: String] {
        var result = [Int: String]()

        for (_, el) in shares.enumerated() {
            let nodeIndex = el.key

            guard
                let k = el.value["ephermalPublicKey"]
            else {
                throw TorusUtilError.runtime("No ephermalPublicKey found in \(el)")
            }
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
                let sharedSecret = ecdh(pubKey: ephemPubKey, privateKey: data)
            else {
                throw TorusUtilError.decryptionFailed
            }
            let sharedSecretData = sharedSecret.data
            let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
            let reversedSharedSecret = sharedSecretPrefix.reversed()

            guard
                let share = el.value["share"]?.fromBase64()?.hexa,
                let iv = el.value["iv"]?.hexa
            else {
                throw TorusUtilError.decryptionFailed
            }

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

    func thresholdLagrangeInterpolation(data filteredData: [Int: String], endpoints: Array<String>, lookupPubkeyX: String, lookupPubkeyY: String) throws -> (String, String, String) {
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
                let pubKeyX = publicKey.prefix(publicKey.count / 2).toHexString()
                let pubKeyY = publicKey.suffix(publicKey.count / 2).toHexString()
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

    func lagrangeInterpolation(shares: [Int: String]) throws -> String {
        let secp256k1N = modulusValue

        // Convert shares to BigInt(Shares)
        var shareList = [BigInt: BigInt]()
        _ = shares.map { shareList[BigInt($0.key + 1)] = BigInt($0.value, radix: 16) }
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

    // MARK: - keylookup

    func awaitKeyLookup(endpoints: Array<String>, verifier: String, verifierId: String, timeout: Int = 0) async throws -> [String: String] {
        let durationInNanoseconds = UInt64(timeout * 1000000000)
        try await Task.sleep(nanoseconds: durationInNanoseconds)
        do {
            return try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        } catch {
            throw error
        }
    }

    public func keyLookup(endpoints: Array<String>, verifier: String, verifierId: String) async throws -> [String: String] {
        // Enode data
        let encoder = JSONEncoder()

        let jsonRPCRequest = JSONRPCrequest(
            method: "VerifierLookupRequest",
            params: ["verifier": verifier, "verifier_id": verifierId])
        guard let rpcdata = try? encoder.encode(jsonRPCRequest)
        else {
            throw TorusUtilError.encodingFailed("\(jsonRPCRequest)")
        }
        var allowHostRequest = try! makeUrlRequest(url: allowHost)
        allowHostRequest.httpMethod = "GET"
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "Origin")
        do {
            _ = try await urlSession.data(for: allowHostRequest)
        } catch {
            os_log("KeyLookup: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }

        // Create Array of URLRequest Promises

        var lookupCount = 0
        var resultArray = Array<[String: String]?>.init(repeating: nil, count: endpoints.count)
        var promisesArray: [(data: Data, response: URLResponse)] = []
        var requestArray = [URLRequest]()
        for (i,el) in endpoints.enumerated(){
            do{
                var rq = try makeUrlRequest(url: el)
                rq.httpBody = rpcdata
                requestArray.append(rq)
            }
            catch{
              throw error
            }
        }
        
        return try await withThrowingTaskGroup(of: Result<TaskGroupResponse,Error>.self, body: { group in
            for (i,rq) in requestArray.enumerated(){
                group.addTask {
                    do{
                        let val = try await self.urlSession.data(for: rq)
                        return .success(.init(data: val.0, urlResponse: val.1, index: i))
                    }
                    catch{
                        return .failure(error)
                    }
                }
            }
            
            for try await val in group{
              //  print("index of the request \( val.1)")
                do{
                    switch val{
                    case .success(let model):
                        let data = model.data
                        let i = model.index
                        do {
                            let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                            os_log("keyLookup: API response: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decoded)")
                            
                            let result = decoded.result
                            let error = decoded.error
                            if let _ = error {
                                resultArray[i] = ["err": decoded.error?.data ?? "nil"]
                            } else {
                                guard
                                    let decodedResult = result as? [String: [[String: String]]],
                                    let k = decodedResult["keys"]
                                else {
                                    throw TorusUtilError.decodingFailed("keys not found in \(result)")
                                }
                                let keys = k[0] as [String: String]
                                resultArray[i] = keys
                            }
                            
                            let lookupShares = resultArray.filter { $0 != nil } // Nonnil elements
                            let keyResult = thresholdSame(arr: lookupShares, threshold: Int(endpoints.count / 2) + 1) // Check if threshold is satisfied
                            
                            if keyResult != nil {
                                os_log("keyLookup: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, keyResult!.debugDescription)
                                return keyResult!!
                            }
                        } catch let err {
                            throw TorusUtilError.decodingFailed(err.localizedDescription)
                        }
                    case .failure(let error):
                        throw error
                    }
                }catch {
                    let tmpError = error as NSError
                    let userInfo = tmpError.userInfo as [String: Any]
                    if tmpError.code == -1003 {
                        // In case node is offline
                        os_log("keyLookup: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)

                        // reject if threshold nodes unavailable
                        lookupCount += 1
                        if lookupCount > Int(endpoints.count / 2) {
                            throw TorusUtilError.nodesUnavailable
                        }
                    } else {
                        // throw TorusUtilError.nodesUnavailable
                        os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    }
                }
            }
            throw TorusUtilError.runtime("keyLookup func failed")
        })
    }

    // MARK: - key assignment

    public func keyAssign(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, signerHost: String, network: EthereumNetworkFND, firstPoint: Int? = nil, lastPoint: Int? = nil) async throws -> JSONRPCresponse {
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
            request.addValue(network.path, forHTTPHeaderField: "network")
            request.httpBody = rpcdata
            do {
                let responseFromSignerData: (Data, URLResponse) = try await urlSession.data(for: request)
                let decodedSignerResponse = try JSONDecoder().decode(SignerResponse.self, from: responseFromSignerData.0)
                os_log("KeyAssign: responseFromSigner: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decodedSignerResponse)")
                let keyassignRequest = KeyAssignRequest(params: ["verifier": verifier, "verifier_id": verifierId], signerResponse: decodedSignerResponse)
                // Combine signer respose and request data
                if #available(macOS 10.13, *) {
                    encoder.outputFormatting = .sortedKeys
                } else {
                    // Fallback on earlier versions
                }
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
                // seal.reject(err)
                return try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network, firstPoint: initialPoint, lastPoint: nodeNum + 1)
            }
        } catch let err {
            throw err
        }
    }

    public func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool = false) async throws -> GetUserAndAddressModel {
        do {
            var data: [String: String] = [:]
            let lookupData = try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID)
            let error = lookupData["err"]
            if error != nil {
                guard let errorString = error else {
                    throw TorusUtilError.runtime("Error not supported")
                }

                // Only assign key in case: Verifier exists and the verifierID doesn't.

                if errorString.contains("Verifier + VerifierID has not yet been assigned") {
                    if !doesKeyAssign {
                        throw TorusUtilError.runtime("Verifier + VerifierID has not yet been assigned")
                    }
                    // Assign key to the user and return (wrapped in a promise)
                    try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePub, verifier: verifier, verifierId: verifierID, signerHost: signerHost, network: network)
                    // Do keylookup again
                    data = try await awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierID, timeout: 1)
                    isNewKey = true
                    let error = data["err"]
                    if error != nil {
                        throw TorusUtilError.configurationError
                    }
                } else {
                    throw error!
                }
            } else {
                data = lookupData
            }
            guard
                let pubKeyX = data["pub_key_X"],
                let pubKeyY = data["pub_key_Y"]
            else {
                throw TorusUtilError.runtime("pub_key_X and pub_key_Y missing from \(data)")
            }
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            let localNonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, getOnly: !isNewKey)
            nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
            typeOfUser = TypeOfUser(rawValue: localNonceResult.typeOfUser) ?? .v1
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
            let val: GetUserAndAddressModel = .init(typeOfUser: typeOfUser, address: publicKeyToAddress(key: modifiedPubKey), x: pubKeyX, y: pubKeyY, pubNonce: localNonceResult.pubNonce, nonceResult: localNonceResult.nonce)
            return val
        } catch {
            throw error
        }
    }

    public func getOrSetNonce(x: String, y: String, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResultModel {
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
            var request = try! makeUrlRequest(url: "\(metaDataHost)/get_or_set_nonce")
            request.httpBody = data
            let val = try await urlSession.data(for: request)
            let decoded = try JSONDecoder().decode(GetOrSetNonceResultModel.self, from: val.0)
            return decoded
        } catch let error {
            throw error
        }
    }

    func generateParams(message: String, privateKey: String) throws -> MetadataParams {
        do {
            guard let privKeyData = Data(hex: privateKey),
                  let publicKey = SECP256K1.privateToPublic(privateKey: privKeyData)?.subdata(in: 1 ..< 65).toHexString()
            else {
                throw TorusUtilError.runtime("invalid priv key")
            }
            let timeStamp = String(BigUInt(serverTimeOffset + Date().timeIntervalSince1970), radix: 16)
            let setData: MetadataParams.SetData = .init(data: message, timestamp: timeStamp)
            let encodedData = try JSONEncoder().encode(setData)
            guard let sigData = SECP256K1.signForRecovery(hash: encodedData.web3.keccak256, privateKey: privKeyData).serializedSignature else {
                throw TorusUtilError.runtime("sign for recovery hash failed")
            }
            let pubKeyX = String(publicKey.prefix(64))
            let pubKeyY = String(publicKey.suffix(64))
            return .init(pub_key_X: pubKeyX, pub_key_Y: pubKeyY, setData: setData, signature: sigData.base64EncodedString())
        } catch let error {
            throw error
        }
    }

    // MARK: - Helper functions

//
//    public func privateKeyToAddress2(key: Data) -> Data{
//        print(key)
//        let publicKey = SECP256K1.privateToPublic(privateKey: key)!
//        let address = Data(publicKey.sha3(.keccak256).suffix(20))
//        return address
//    }

    public func publicKeyToAddress(key: Data) -> Data {
        return key.web3.keccak256.suffix(20)
    }

    public func publicKeyToAddress(key: String) -> String {
        return key.web3.keccak256fromHex.suffix(20).toHexString().toChecksumAddress()
    }

    func combinePublicKeys(keys: [String], compressed: Bool) -> String {
        let data = keys.map({ Data.fromHex($0)! })
        let added = SECP256K1.combineSerializedPublicKeys(keys: data)
        return (added?.toHexString())!
    }

    func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }

    func array32toTuple(_ arr: Array<UInt8>) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
        return (arr[0] as UInt8, arr[1] as UInt8, arr[2] as UInt8, arr[3] as UInt8, arr[4] as UInt8, arr[5] as UInt8, arr[6] as UInt8, arr[7] as UInt8, arr[8] as UInt8, arr[9] as UInt8, arr[10] as UInt8, arr[11] as UInt8, arr[12] as UInt8, arr[13] as UInt8, arr[14] as UInt8, arr[15] as UInt8, arr[16] as UInt8, arr[17] as UInt8, arr[18] as UInt8, arr[19] as UInt8, arr[20] as UInt8, arr[21] as UInt8, arr[22] as UInt8, arr[23] as UInt8, arr[24] as UInt8, arr[25] as UInt8, arr[26] as UInt8, arr[27] as UInt8, arr[28] as UInt8, arr[29] as UInt8, arr[30] as UInt8, arr[31] as UInt8, arr[32] as UInt8, arr[33] as UInt8, arr[34] as UInt8, arr[35] as UInt8, arr[36] as UInt8, arr[37] as UInt8, arr[38] as UInt8, arr[39] as UInt8, arr[40] as UInt8, arr[41] as UInt8, arr[42] as UInt8, arr[43] as UInt8, arr[44] as UInt8, arr[45] as UInt8, arr[46] as UInt8, arr[47] as UInt8, arr[48] as UInt8, arr[49] as UInt8, arr[50] as UInt8, arr[51] as UInt8, arr[52] as UInt8, arr[53] as UInt8, arr[54] as UInt8, arr[55] as UInt8, arr[56] as UInt8, arr[57] as UInt8, arr[58] as UInt8, arr[59] as UInt8, arr[60] as UInt8, arr[61] as UInt8, arr[62] as UInt8, arr[63] as UInt8)
    }
}

// Necessary for decryption

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(utf8).base64EncodedString()
    }

    func strip04Prefix() -> String {
        if hasPrefix("04") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func strip0xPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func addLeading0sForLength64() -> String {
        if count < 64 {
            let toAdd = String(repeating: "0", count: 64 - count)
            return toAdd + self
        } else {
            return self
        }
        // String(format: "%064d", self)
    }
}

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        return (0 ..< count / 2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            return UInt8(self[startIndex ... endIndex], radix: 16)
        }
    }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}

extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j ..< k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }

    func addLeading0sForLength64() -> Data {
        Data(hex: toHexString().addLeading0sForLength64())
    }
}



