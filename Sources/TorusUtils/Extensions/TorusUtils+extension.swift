//
//  File.swift
//  
//
//  Created by Shubham on 25/3/20.
//

import Foundation
import CommonCrypto
import PromiseKit
import FetchNodeDetails
#if canImport(PMKFoundation)
import PMKFoundation
#endif
#if canImport(secp256k1)
import secp256k1
#endif
import BigInt
import web3
import CryptoSwift
import OSLog
import os

extension TorusUtils {
    
    // MARK:- utils
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
            throw TorusError.decodingFailed
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
        if (privateKey.count != 32) {return nil}
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, let ctx = TorusUtils.context, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_pubkey_tweak_mul(
                    ctx, UnsafeMutablePointer<secp256k1_pubkey>(&localPubkey), privateKeyPointer)
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
    func getMetadata(dictionary: [String:String]) -> Promise<BigUInt>{
        let (promise, seal) = Promise<BigUInt>.pending()
        
        let encoded: Data?
        do {
            encoded = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            seal.reject(error)
            return promise
        }
        
        guard let encoded = encoded else {
            seal.reject(TorusError.runtime("Unable to serialize dictionary into JSON."))
            return promise
        }
        let request = try! self.makeUrlRequest(url: "https://metadata.tor.us/get")
        let task = URLSession.shared.uploadTask(.promise, with: request, from: encoded)
        task.compactMap {
            try JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
        }.done{ data in
            os_log("getMetadata: %@", log: getTorusLogger(log: TorusUtilsLogger.network, type: .info), type: .info, data)
            guard
                    let msg: String = data["message"] as? String,
                    let ret = BigUInt(msg, radix: 16)
                    else {
                throw TorusError.decodingFailed
            }
            seal.fulfill(ret)
        }.catch{ _ in
            seal.fulfill(BigUInt("0", radix: 16)!)
        }
        
        return promise
    }
    
    // MARK:- retreiveDecryptAndReconstuct
    func retrieveDecryptAndReconstruct(endpoints : Array<String>, extraParams: Data, verifier: String, tokenCommitment:String, nodeSignatures: [[String:String]], verifierId: String, lookupPubkeyX: String, lookupPubkeyY: String, privateKey: String) -> Promise<(String, String, String)>{
        // Rebuild extraParams
        var rpcdata : Data = Data.init()
        do {
            if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(extraParams) as? [String:Any] {
                let value = ["verifieridentifier":verifier, "verifier_id": verifierId, "nodesignatures": nodeSignatures, "idtoken": tokenCommitment] as [String : Any]
                let keepingCurrent = loadedStrings.merging(value) { (current, _) in current }
                // TODO : Look into hetrogeneous array encoding
                let dataForRequest = ["jsonrpc": "2.0",
                                      "id":10,
                                      "method": "ShareRequest",
                                      "params": ["encrypted": "yes",
                                                 "item": [keepingCurrent]]] as [String : Any]
                rpcdata = try JSONSerialization.data(withJSONObject: dataForRequest)
            }
        } catch {
            os_log("retrieveDecryptAndReconstruct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }
        
        // Build promises array
        var requestPromises = Array<Promise<(data: Data, response: URLResponse)> >()
       
        
        // Return promise
        let (promise, seal) = Promise<(String, String, String)>.pending()
        for el in endpoints {
            do {
                let rq = try self.makeUrlRequest(url: el)
                requestPromises.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
            } catch {
                seal.reject(error)
                return promise
            }
        }
        var globalCount = 0
        var shareResponses = Array<[String:String]?>.init(repeating: nil, count: requestPromises.count)
        var resultArray = [Int:[String:String]]()
        var errorStack = [Error]()
        for (i, rq) in requestPromises.enumerated(){
            rq.then{ data, response -> Promise<[Int:String]> in
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                if(decoded.error != nil) {
                    throw TorusError.decodingFailed
                }
                os_log("retrieveDecryptAndReconstuct: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, "\(decoded)")
                
                guard
                    let decodedResult = decoded.result as? [String:Any],
                    let keyObj = decodedResult["keys"] as? [[String:Any]]
                else { throw TorusError.decodingFailed }

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
                        throw TorusError.decodingFailed
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
                
                let lookupShares = shareResponses.filter{ $0 != nil } // Nonnil elements
                
                // Comparing dictionaries, so the order of keys doesn't matter
                let keyResult = self.thresholdSame(arr: lookupShares.map{$0}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                if(keyResult != nil && !promise.isFulfilled){
                    os_log("retreiveIndividualNodeShares - result: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, resultArray)
                    return self.decryptIndividualShares(shares: resultArray, privateKey: privateKey)
                }else{
                    throw TorusError.empty
                }
            }.then{ data -> Promise<(String, String, String)> in
                os_log("retrieveDecryptAndReconstuct - data after decryptIndividualShares: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data)
                let filteredData = data.filter{$0.value != TorusError.decodingFailed.debugDescription}
                if(filteredData.count < Int(endpoints.count/2)+1){ throw TorusError.thresholdError }
                return self.thresholdLagrangeInterpolation(data: filteredData, endpoints: endpoints, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY)
            }.done{ x, y, z in
                seal.fulfill((x, y, z))
            }.catch{ err in
                errorStack.append(err)
                let nsErr = err as NSError
                let userInfo = nsErr.userInfo as [String: Any]
                if(nsErr.code == -1003){
                    // In case node is offline
                    os_log("retrieveDecryptAndReconstuct: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)
                }else if let err = (err as? TorusError) {
                    if(err == TorusError.thresholdError){
                        os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
                    }
                }else{
                    os_log("retrieveDecryptAndReconstuct - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
                }
            }.finally{
                globalCount+=1;
                if (globalCount == endpoints.count && promise.isPending) {
                    seal.reject(TorusError.runtime("Unable to reconstruct: \(errorStack)"))
                }
            }
        }
        return promise
    }
    
    // MARK:- commitment request
    func commitmentRequest(endpoints : Array<String>, verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) -> Promise<[[String:String]]>{
        let (promise, seal) = Promise<[[String:String]]>.pending()
        
        let encoder = JSONEncoder()
        guard let rpcdata = try? encoder.encode(JSONRPCrequest(
            method: "CommitmentRequest",
            params: ["messageprefix": "mug00",
                     "tokencommitment": tokenCommitment,
                     "temppubx": pubKeyX,
                     "temppuby": pubKeyY,
                     "verifieridentifier":verifier,
                     "timestamp": timestamp]
        ))
        else {
            seal.reject(TorusError.runtime("Unable to encode request."))
            return promise
        }
        
        // Build promises array
        var requestPromises = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            do {
                let rq = try self.makeUrlRequest(url: el);
                requestPromises.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
            } catch {
                seal.reject(error)
                return promise
            }
        }
        
        // Array to store intermediate results
        var resultArrayStrings = Array<Any?>.init(repeating: nil, count: requestPromises.count)
        var resultArrayObjects = Array<JSONRPCresponse?>.init(repeating: nil, count: requestPromises.count)
        var lookupCount = 0
        var globalCount = 0
        for (i, rq) in requestPromises.enumerated(){
            rq.done{ data, response in
                let encoder = JSONEncoder()
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                os_log("commitmentRequest - reponse: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, decoded.message ?? "")

                if(decoded.error != nil) {
                    os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, decoded.error?.message ?? "")
                    throw TorusError.commitmentRequestFailed
                }
                
                // Check if k+t responses are back
                resultArrayStrings[i] = String(data: try encoder.encode(decoded), encoding: .utf8)
                resultArrayObjects[i] = decoded
                
                let lookupShares = resultArrayStrings.filter{ $0 as? String != nil } // Nonnil elements
                if(lookupShares.count >= Int(endpoints.count/4)*3+1 && !promise.isFulfilled){
                    let nodeSignatures = try resultArrayObjects.compactMap{ $0 }.map{ (a: JSONRPCresponse) throws -> [String: String] in
                        guard
                            let r = a.result as? [String:String]
                        else {
                            throw TorusError.decodingFailed
                        }
                        return r
                        
                    }
                    os_log("commitmentRequest - nodeSignatures: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, nodeSignatures)
                    seal.fulfill(nodeSignatures)
                }
            }.catch{ err in
                let nsErr = err as NSError
                let userInfo = nsErr.userInfo as [String: Any]
                if(nsErr.code == -1003){
                    // In case node is offline
                    os_log("commitmentRequest: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)

                    // Reject if threshold nodes unavailable
                    lookupCount+=1
                    if(!promise.isFulfilled && (lookupCount > endpoints.count)){
                        seal.reject(TorusError.nodesUnavailable)
                    }
                }else{
                    os_log("commitmentRequest - error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
                }
            }.finally{
                globalCount+=1;
                if (globalCount == endpoints.count && promise.isPending) {
                    seal.reject(TorusError.commitmentRequestFailed)
                }
            }
        }
        return promise
    }
    
    // MARK:- decrypt shares
    func decryptIndividualShares(shares: [Int:[String:String]], privateKey: String) -> Promise<[Int:String]>{
        let (tempPromise, seal) = Promise<[Int:String]>.pending()
        
        var result = [Int:String]()
        
        for(_, el) in shares.enumerated(){
            
            let nodeIndex = el.key

            guard
                    let k = el.value["ephermalPublicKey"]
                    else {
                seal.reject(TorusError.decodingFailed)
                break
            }
            let ephermalPublicKey = k.strip04Prefix()
            let ephermalPublicKeyBytes = ephermalPublicKey.hexa
            var ephermOne = ephermalPublicKeyBytes.prefix(32)
            var ephermTwo = ephermalPublicKeyBytes.suffix(32)
            // Reverse because of C endian array storage
            ephermOne.reverse(); ephermTwo.reverse();
            ephermOne.append(contentsOf: ephermTwo)
            let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne)))

            guard
                    // Calculate g^a^b, i.e., Shared Key
                    let data = Data(hexString: privateKey),
                    let sharedSecret = self.ecdh(pubKey: ephemPubKey, privateKey: data)
                    else {
                seal.reject(TorusError.decryptionFailed)
                break
            }
            let sharedSecretData = sharedSecret.data
            let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
            let reversedSharedSecret = sharedSecretPrefix.reversed()
            // print(sharedSecretPrefix.hexa, reversedSharedSecret.hexa)

            guard
                    let share = el.value["share"]?.fromBase64()?.hexa,
                    let iv = el.value["iv"]?.hexa
                    else {
                seal.reject(TorusError.decryptionFailed)
                break
            }
            
            let newXValue = reversedSharedSecret.hexa
            let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
            let AesEncryptionKey = hash.prefix(64)
            
            do{
                // AES-CBCblock-256
                let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv), padding: .pkcs7)
                let decrypt = try aes.decrypt(share)
                result[nodeIndex] = decrypt.hexa
            }catch{
                result[nodeIndex] = TorusError.decodingFailed.debugDescription
            }
            if(shares.count == result.count) {
                seal.fulfill(result) // Resolve if all shares decrypt
            }
        }
        return tempPromise
    }
    
    // MARK:- Lagrange interpolation
    func thresholdLagrangeInterpolation(data filteredData: [Int: String], endpoints: Array<String>, lookupPubkeyX: String, lookupPubkeyY: String) -> Promise<(String, String, String)>{
        
        let (tempPromise, seal) = Promise<(String, String, String)>.pending()
        // all possible combinations of share indexes to interpolate
        let shareCombinations = self.combinations(elements: Array(filteredData.keys), k: Int(endpoints.count/2)+1)
        var totalInterpolations = 0
        for shareIndexSet in shareCombinations{
            var sharesToInterpolate: [Int:String] = [:]
            shareIndexSet.forEach{ sharesToInterpolate[$0] = filteredData[$0]}
            self.lagrangeInterpolation(shares: sharesToInterpolate).done{data -> Void in
                // Split key in 2 parts, X and Y

                guard let finalPrivateKey = data.web3.hexData, let publicKey = SECP256K1.privateToPublic(privateKey: finalPrivateKey)?.subdata(in: 1..<65) else{
                    seal.reject(TorusError.decodingFailed)
                    return
                }
                
                let pubKeyX = publicKey.prefix(publicKey.count/2).toHexString()
                let pubKeyY = publicKey.suffix(publicKey.count/2).toHexString()
                os_log("retrieveDecryptAndReconstuct: private key rebuild %@ %@ %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, data, pubKeyX, pubKeyY)
                
                // Verify
                if( pubKeyX == lookupPubkeyX && pubKeyY == lookupPubkeyY) {
                    seal.fulfill((pubKeyX, pubKeyY, data))
                }else{
                    os_log("retrieveDecryptAndReconstuct: verification failed", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error)
                }
            }.catch{err in
                os_log("retrieveDecryptAndReconstuct: lagrangeInterpolation: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
            }.finally {
                totalInterpolations += 1
                if(tempPromise.isPending && totalInterpolations > (shareCombinations.count-1)){
                    seal.reject(TorusError.interpolationFailed)
                }
            }
        }
        
        return tempPromise
    }
    
    func lagrangeInterpolation(shares: [Int:String]) -> Promise<String>{
        let (tempPromise, seal) = Promise<String>.pending()
        let secp256k1N = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!;
        
        // Convert shares to BigInt(Shares)
        var shareList = [BigInt:BigInt]()
        _ = shares.map { shareList[BigInt($0.key+1)] = BigInt($0.value, radix: 16)}
        os_log("lagrangeInterpolation: %@ %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, shares, shareList)
        
        var secret = BigUInt("0") // to support BigInt 4.0 dependency on cocoapods
        let serialQueue = DispatchQueue(label: "lagrange.serial.queue")
        let semaphore = DispatchSemaphore(value: 1)
        var sharesDecrypt = 0
        
        for (i, share) in shareList {
            serialQueue.async{
                
                // Wait for signal
                semaphore.wait()
                
                var upper = BigInt(1);
                var lower = BigInt(1);
                for (j, _) in shareList {
                    if (i != j) {
                        
                        let negatedJ = j*BigInt(-1)
                        upper = upper*negatedJ
                        upper = upper.modulus(secp256k1N)
                        
                        var temp = i-j;
                        temp = temp.modulus(secp256k1N);
                        lower = (lower*temp).modulus(secp256k1N);
                    }
                }
                guard
                        let inv = lower.inverse(secp256k1N)
                        else {
                    seal.reject(TorusError.decryptionFailed)
                    return
                }
                var delta = (upper * inv).modulus(secp256k1N)
                delta = (delta*share).modulus(secp256k1N)
                secret = BigUInt((BigInt(secret)+delta).modulus(secp256k1N))
                sharesDecrypt += 1
                
                let secretString = String(secret.serialize().hexa.suffix(64))
                if(sharesDecrypt == shareList.count){
                    seal.fulfill(secretString)
                }
                semaphore.signal()
            }
        }
        return tempPromise
    }
    
    // MARK:- keylookup
    public func keyLookup(endpoints : Array<String>, verifier : String, verifierId : String) -> Promise<[String:String]>{
        let (tempPromise, seal) = Promise<[String:String]>.pending()
        
        // Enode data
        let encoder = JSONEncoder()
        guard
                let rpcdata = try? encoder.encode(
                        JSONRPCrequest(
                                method: "VerifierLookupRequest",
                                params: ["verifier": verifier, "verifier_id": verifierId]))
                else {
            seal.reject(TorusError.decodingFailed)
            return tempPromise
        }

        // allowHost = 'https://signer.tor.us/api/allow'
        var allowHostRequest = try! self.makeUrlRequest(url:  "https://signer.tor.us/api/allow")
        allowHostRequest.httpMethod = "GET"
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "Origin")
        URLSession.shared.dataTask(.promise, with: allowHostRequest).done{ data in
            // swallow
        }.catch{error in
            os_log("KeyLookup: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
        }
        
        // Create Array of URLRequest Promises
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            do {
                let rq = try self.makeUrlRequest(url: el)
                promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
            } catch {
                seal.reject(error)
                return tempPromise
            }
        }
        
        var lookupCount = 0
        var resultArray = Array<[String:String]?>.init(repeating: nil, count: promisesArray.count)
        
        
        for (i, pr) in promisesArray.enumerated() {
            pr.done{ data, response in
                // os_log("keyLookup: err: %s", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error,  String(decoding: data, as: UTF8.self))
                guard
                    let decoded = try? JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                        else {
                    throw TorusError.decodingFailed
                }
                os_log("keyLookup: API response: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decoded)" )

                let result = decoded.result
                let error = decoded.error
                if let _ = error {
                    resultArray[i] = ["err": decoded.error?.data ?? "nil"]
                } else {
                    guard
                        let decodedResult = result as? [String: [[String: String]]],
                        let k = decodedResult["keys"]

                    else {
                        throw TorusError.decodingFailed
                    }
                    let keys = k[0] as [String: String]
                    resultArray[i] = keys
                }
                
                
                let lookupShares = resultArray.filter{ $0 != nil } // Nonnil elements
                let keyResult = self.thresholdSame(arr: lookupShares, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                
                if(keyResult != nil && !tempPromise.isFulfilled)  {
                    os_log("keyLookup: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, keyResult!.debugDescription)
                    seal.fulfill(keyResult!!)
                }
            }.catch{error in
                let tmpError = error as NSError
                let userInfo = tmpError.userInfo as [String: Any]
                if(tmpError.code == -1003){
                    // In case node is offline
                    os_log("keyLookup: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)
                    
                    // reject if threshold nodes unavailable
                    lookupCount += 1
                    if(!tempPromise.isFulfilled && (lookupCount > Int(endpoints.count/2))){
                        seal.reject(TorusError.nodesUnavailable)
                    }
                }else{
                    os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                }
            }
        }
        return tempPromise
    }
    
    // MARK:- key assignment
    public func keyAssign(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String) -> Promise<JSONRPCresponse> {
        let (tempPromise, seal) = Promise<JSONRPCresponse>.pending()
        os_log("KeyAssign: endpoints: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, endpoints)
        var newEndpoints = endpoints
        let newEndpoints2 = newEndpoints // used for maintaining indexes
        newEndpoints.shuffle() // To avoid overloading a single node
        
        // Serial execution required because keyassign should be done only once
        let serialQueue = DispatchQueue(label: "keyassign.serial.queue")
        let semaphore = DispatchSemaphore(value: 1)
        
        for (i, endpoint) in newEndpoints.enumerated() {
            serialQueue.async {
                // Wait for the signal
                semaphore.wait()
                
                let encoder = JSONEncoder()
                if #available(iOS 11.0, *) {
                    encoder.outputFormatting = .sortedKeys
                } else {
                    // Fallback on earlier versions
                }
                guard
                    let index = newEndpoints2.firstIndex(of: endpoint)
                else {
                    seal.reject(TorusError.decodingFailed)
                    return
                }
                os_log("KeyAssign: %d , endpoint: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, index, endpoint)
                
                let SignerObject = JSONRPCrequest(method: "KeyAssign", params: ["verifier":verifier, "verifier_id":verifierId])
                guard
                    let rpcdata = try? encoder.encode(SignerObject)
                else {
                    seal.reject(TorusError.decodingFailed)
                    return
                }
                var request = try! self.makeUrlRequest(url:  "https://signer.tor.us/api/sign")
                request.addValue(torusNodePubs[index].getX().lowercased(), forHTTPHeaderField: "pubKeyX")
                request.addValue(torusNodePubs[index].getY().lowercased(), forHTTPHeaderField: "pubKeyY")
            
                firstly {
                    URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
                }.then{ data, _ -> Promise<(data: Data, response: URLResponse)> in
                    let decodedSignerResponse = try JSONDecoder().decode(SignerResponse.self, from: data)
                    os_log("KeyAssign: responseFromSigner: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decodedSignerResponse)")
                    
                    let keyassignRequest = KeyAssignRequest(params: ["verifier":verifier, "verifier_id":verifierId], signerResponse: decodedSignerResponse)
                    
                    // Combine signer respose and request data
                    if #available(iOS 11.0, *) {
                        encoder.outputFormatting = .sortedKeys
                    } else {
                        // Fallback on earlier versions
                    }
                    guard
                        let newData = try? encoder.encode(keyassignRequest),
                        let request = try? self.makeUrlRequest(url: endpoint)
                    else{
                        throw TorusError.decodingFailed
                    }
                    
                    return URLSession.shared.uploadTask(.promise, with: request, from: newData)
                }.done{ data, _ in
                    guard
                        let decodedData = try? JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                    else{
                        throw TorusError.decodingFailed
                    }
                    os_log("keyAssign: fullfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, decodedData.message ?? "")
                    if(!tempPromise.isFulfilled){
                        seal.fulfill(decodedData)
                    }
                    // semaphore.signal() // Signal to start again
                }.catch{ err in
                    os_log("KeyAssign: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
                    // Reject only if reached the last point
                    if(i+1==endpoint.count) {
                        seal.reject(err)
                    }
                    // Signal to start again
                    semaphore.signal()
                }
                
            }
        }
        return tempPromise
        
    }
    
    // MARK:- Helper functions
//
//    public func privateKeyToAddress(key: Data) -> Data{
//        print(key)
//        let publicKey = SECP256K1.privateToPublic(privateKey: key)!
//        let address = Data(publicKey.sha3(.keccak256).suffix(20))
//        return address
//    }
//
    func generatePrivateKeyData() -> Data? {
        return Data.randomOfLength(32)
    }
    
    public func publicKeyToAddress(key: Data) -> Data{
        return Data(key.sha3(.keccak256).suffix(20))
    }
    
    public func publicKeyToAddress(key: String) -> String{
        return String(key.sha3(.keccak256).suffix(20))
    }
    
    func combinePublicKeys(keys: [String], compressed: Bool) -> String{
        let data = keys.map({ return Data(hex: $0)})
        let added = SECP256K1.combineSerializedPublicKeys(keys: data)
        return (added?.toHexString())!
    }
    
    func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }
    
    func array32toTuple(_ arr: Array<UInt8>) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8){
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
        return Data(self.utf8).base64EncodedString()
    }
    
    func strip04Prefix() -> String {
        if self.hasPrefix("04") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }
    
    func strip0xPrefix() -> String {
        if self.hasPrefix("0x") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }
    
    func addLeading0sForLength64() -> String{
        if self.count < 64 {
            let toAdd = String(repeating: "0", count: 64 - self.count)
            return toAdd + self
        }else {
            return self
        }
        // String(format: "%064d", self)
    }
}

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        //print(startIndex, count)
        return (0..<count/2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            // print(startIndex, endIndex)
            return UInt8(self[startIndex...endIndex], radix: 16)
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
            let bytes = hexString[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    func addLeading0sForLength64() -> Data{
        Data(hex: self.toHexString().addLeading0sForLength64())
    }
}
