/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import FetchNodeDetails
import web3swift
import PromiseKit
import secp256k1
import PMKFoundation
import CryptoSwift
import BigInt


public class TorusUtils{
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    var privateKey = ""
    
    public init(){
        
    }
    
    func getMetadata() -> Promise<BigInt>{
        return Promise<BigInt>.value(BigInt(0))
    }
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String, isExtended: Bool) -> Promise<[String:String]>{

        let (tempPromise, seal) = Promise<[String:String]>.pending()
        let keyLookup = self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)

        keyLookup.then{ lookupData -> Promise<[String: String]> in
            let error = lookupData["err"]
            
            if(error != nil){
                // Assign key to the user and return (wraped in a promise)
                return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<[String:String]> in
                    // Do keylookup again
                    return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                }.then{ data -> Promise<[String: String]> in
                   
                    return Promise<[String: String]>.value(data)
                }
            }else{
                return Promise<[String: String]>.value(lookupData)
            }
        }.done{ data in
            
            if(!isExtended){
                seal.fulfill(["address": data["address"]!])
            }else{
                seal.fulfill(data)
            }
        }.catch{err in
            print("err", err)
        }

        return tempPromise

    }
    
    func commitmentRequest(endpoints : Array<String>, verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) -> Promise<[[String:String]]>{
        
        let (tempPromise, seal) = Promise<[[String:String]]>.pending()
        
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            let encoder = JSONEncoder()
            let rpcdata = try! encoder.encode(JSONRPCrequest(
                method: "CommitmentRequest",
                params: ["messageprefix": "mug00",
                         "tokencommitment": tokenCommitment,
                         "temppubx": pubKeyX,
                         "temppuby": pubKeyY,
                         "verifieridentifier":verifier,
                         "timestamp": timestamp]
            ))
            // print( String(data: rpcdata, encoding: .utf8)!)
            promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        
        // Array to store intermediate results
        var resultArrayStrings = Array<Any?>.init(repeating: nil, count: promisesArray.count)
        var resultArrayObjects = Array<JSONRPCresponse?>.init(repeating: nil, count: promisesArray.count)
        var isTokenCommitmentDone = false
        
        for (i, pr) in promisesArray.enumerated(){
            pr.then{ data, response -> Promise<[JSONRPCresponse?]> in
                // print(String(data: data, encoding: .utf8))
                
                let encoder = JSONEncoder()
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                // print("response", decoded)
                
                if(decoded.error != nil) {
                    print(decoded)
                    throw "decoding error"
                }
                
                // check if k+t responses are back
                resultArrayStrings[i] = String(data: try encoder.encode(decoded), encoding: .utf8)
                resultArrayObjects[i] = decoded
                
                let lookupShares = resultArrayStrings.filter{ $0 as? String != nil } // Nonnil elements
                if(lookupShares.count >= Int(endpoints.count/4)*3+1 && !isTokenCommitmentDone){
                    // print("resolving some promise")
                    isTokenCommitmentDone = true
                    return Promise<[JSONRPCresponse?]>.value(resultArrayObjects)
                }
                else{
                    //  let errorJSONRPCResponse = JSONRPCresponse(id: 1, jsonrpc: "2.0", result: nil, error: nil)
                    return Promise.init(error: "LookupShares.count is \(lookupShares.count), Commitment didn't succeed with at \(i)")
                }
            }.done{ data in
                //print("After token commitment: array of JSONRPCResponses", data )
                var nodeSignatures: [[String:String]] = []
                for el in data{
                    if(el != nil){
                        nodeSignatures.append(el?.result as! [String:String])
                    }
                }
                seal.fulfill(nodeSignatures)
            }.catch{ err in
                // print(err)
                // seal.reject(err)
            }
        }
        return tempPromise
    }
    
    func retreiveIndividualNodeShare(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String, nodeSignatures: [[String:String]]) -> Promise<[Int:[String:String]]>{
        let (tempPromise, seal) = Promise<[Int:[String:String]]>.pending()
        
        var promisesArrayReq = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            
            // todo : look into hetrogeneous array encoding
            let dataForRequest = ["jsonrpc": "2.0",
                                  "id":10,
                                  "method": "ShareRequest",
                                  "params": ["encrypted": "yes",
                                             "item": [["verifieridentifier":verifier, "verifier_id": verifierParams["verifier_id"]!, "idtoken": idToken, "nodesignatures": nodeSignatures]]]] as [String : Any]
            
            let rpcdata = try! JSONSerialization.data(withJSONObject: dataForRequest)
            // print( String(data: rpcdata, encoding: .utf8)!)
            promisesArrayReq.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        
        var ShareResponses = Array<[String:String]?>.init(repeating: nil, count: promisesArrayReq.count)
        var resultArray = [Int:[String:String]]()
        
        var receivedRequiredShares = false
        for (i, pr) in promisesArrayReq.enumerated(){
            pr.done{ data, response in
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                // print("share responses", decoded)
                if(decoded.error != nil) {throw "decoding error"}
                
                let decodedResult = decoded.result as? [String:Any]
                let keyObj = decodedResult!["keys"] as? [[String:Any]]
                let metadata = keyObj?[0]["Metadata"] as! [String : String]
                let share = keyObj?[0]["Share"] as! String
                let publicKey = keyObj?[0]["PublicKey"] as! [String : String]
                // print("publicKey", publicKey)
                ShareResponses[i] = publicKey //For threshold
                //resultArrayObjects[i] = decoded
                resultArray[i] = ["iv": metadata["iv"]!, "ephermalPublicKey": metadata["ephemPublicKey"]!, "share": share, "pubKeyX": publicKey["X"]!, "pubKeyY": publicKey["Y"]!]
                
                // let publicKeyString = String(data: try JSONSerialization.data(withJSONObject: publicKey), encoding: .utf8)
                let lookupShares = ShareResponses.filter{ $0 != nil } // Nonnil elements
                
                // Comparing dictionaries, so the order of keys doesn't matter
                let keyResult = self.thresholdSame(arr: lookupShares.map{$0}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                if(keyResult != nil && !receivedRequiredShares){
                    receivedRequiredShares = true
                    seal.fulfill(resultArray)
                }else{
                    // print("All public keys ain't matchin \(i)")
                    // return Promise.init(error: "All public keys ain't matchin \(i)")
                }
            }.catch{ err in
                print(err)
            }
        }
        return tempPromise
    }
    
    func decryptIndividualShares(shares: [Int:[String:String]], privateKey: String) -> Promise<[Int:String]>{
        let (tempPromise, seal) = Promise<[Int:String]>.pending()
        
        var result = [Int:String]()
        
        for(i, el) in shares.enumerated(){
            
            let nodeIndex = el.key
            
            let ephermalPublicKey = el.value["ephermalPublicKey"]?.strip04Prefix()
            let ephermalPublicKeyBytes = ephermalPublicKey?.hexa
            var ephermOne = ephermalPublicKeyBytes?.prefix(32)
            var ephermTwo = ephermalPublicKeyBytes?.suffix(32)
            // Reverse because of C endian array storage
            ephermOne?.reverse(); ephermTwo?.reverse();
            ephermOne?.append(contentsOf: ephermTwo!)
            let ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(ephermOne!)))
            
            // Calculate g^a^b, i.e., Shared Key
            let sharedSecret = ecdh(pubKey: ephemPubKey, privateKey: Data.init(hexString: privateKey)!)
            let sharedSecretData = sharedSecret!.data
            let sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
            let reversedSharedSecret = sharedSecretPrefix.reversed()
            // print(sharedSecretPrefix.hexa, reversedSharedSecret.hexa)
            
            let share = el.value["share"]!.fromBase64()!.hexa
            let iv = el.value["iv"]?.hexa
            
            let newXValue = reversedSharedSecret.hexa
            let hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
            let AesEncryptionKey = hash.prefix(64)
            
            do{
                // AES-CBCblock-256
                let aes = try AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv!), padding: .pkcs7)
                let decrypt = try aes.decrypt(share)
                result[nodeIndex] = decrypt.hexa
                // print(result)
                
                if(shares.count == result.count) {
                    // print("result", result)
                    seal.fulfill(result)
                }
                // print("decrypt", decrypt.hexa)
            }catch{
                print("padding error")
                seal.reject("Padding error")
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
        print(shares, shareList)
        
        var secret = BigInt("0")
        let serialQueue = DispatchQueue(label: "lagrange.serial.queue")
        let semaphore = DispatchSemaphore(value: 1)
        var sharesDecrypt = 0
        
        for (i, share) in shareList {
            serialQueue.async{
                
                // Wait for signal
                semaphore.wait()
                
                //print(i, share)
                var upper = BigInt(1);
                var lower = BigInt(1);
                for (j, _) in shareList {
                    if (i != j) {
                        // print(j, i)
                        let negatedJ = j*BigInt(-1)
                        upper = upper*negatedJ
                        upper = upper.modulus(secp256k1N)
                        
                        var temp = i-j;
                        temp = temp.modulus(secp256k1N);
                        lower = (lower*temp).modulus(secp256k1N);
                        // print("i \(i) j \(j) upper \(upper) lower \(lower)")
                    }
                }
                var delta = (upper*(lower.inverse(secp256k1N)!)).modulus(secp256k1N);
                // print("delta", delta, "inverse of lower", lower.inverse(secp256k1N)!)
                delta = (delta*share).modulus(secp256k1N)
                secret = (secret+delta).modulus(secp256k1N)
                sharesDecrypt += 1
                
                let secretString = String(secret.serialize().hexa.suffix(64))
                // print("secret is", secretString, secret, "\n")
                if(sharesDecrypt == shareList.count){
                   seal.fulfill(secretString)
                }
                semaphore.signal()
            }
        }
        return tempPromise
    }
    
    public func retreiveShares(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String){
        // Generate pubkey-privatekey
        let privateKey = SECP256K1.generatePrivateKey()
        let publicKey = SECP256K1.privateToPublic(privateKey: privateKey!, compressed: false)?.suffix(64) // take last 64
        
        // Split key in 2 parts, X and Y
        let publicKeyHex = publicKey?.toHexString()
        let pubKeyX = publicKey?.prefix(publicKey!.count/2).toHexString()
        let pubKeyY = publicKey?.suffix(publicKey!.count/2).toHexString()
        
        // Hash the token from OAuth login
        let tokenCommitment = idToken.sha3(.keccak256)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        var nodeReturnedPubKeyX:String = ""
        var nodeReturnedPubKeyY:String = ""
        
        print(privateKey?.toHexString() as Any, publicKeyHex as Any, pubKeyX as Any, pubKeyY as Any, tokenCommitment)
        
        commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX!, pubKeyY: pubKeyY!, timestamp: timestamp, tokenCommitment: tokenCommitment)
            .then{ data -> Promise<[Int:[String:String]]> in
                nodeReturnedPubKeyX = data[0]["pubKeyX"]!
                nodeReturnedPubKeyY = data[0]["pubKeyY"]!
                return self.retreiveIndividualNodeShare(endpoints: endpoints, verifier: verifier, verifierParams: verifierParams, idToken: idToken, nodeSignatures: data)
            }.then{ data -> Promise<[Int:String]> in
                // print("data after retrieve shares", data)
                return self.decryptIndividualShares(shares: data, privateKey: privateKey!.toHexString())
            }.then{ data -> Promise<String> in
                print("individual shares array", data)
                return self.lagrangeInterpolation(shares: data)
            }.done{ data in
                print("private key rebuild", data)
                
                let publicKey = SECP256K1.privateToPublic(privateKey: Data.init(hex: data) , compressed: false)?.suffix(64) // take last 64
                
                // Split key in 2 parts, X and Y
                // let publicKeyHex = publicKey?.toHexString()
                let pubKeyX = publicKey?.prefix(publicKey!.count/2).toHexString()
                let pubKeyY = publicKey?.suffix(publicKey!.count/2).toHexString()
                
                // Verify
                if( pubKeyX == nodeReturnedPubKeyX && pubKeyY == nodeReturnedPubKeyY) {
                    self.privateKey = data
                }else{
                    throw "could not derive private key"
                }
                
                return Promise<String>.value(data)
                print("final private key", self.privateKey)
            }.catch{
                err in print(err)
            }
    }
}
