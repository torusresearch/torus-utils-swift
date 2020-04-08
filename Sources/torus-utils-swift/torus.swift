/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import fetch_node_details
import web3swift
import PromiseKit
import secp256k1
import PMKFoundation
import CryptoSwift
import BigInt


public class Torus{
    public var torusUtils : utils = utils()
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    
    public init(){
        
    }
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String, isExtended: Bool) -> Promise<[String:String]>{
        
        let (tempPromise, seal) = Promise<[String:String]>.pending()
        let keyLookup = self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        
        keyLookup.map{ tempData in
            //print(tempData)
            try JSONSerialization.jsonObject(with: Data(tempData.utf8)) as! [String : Any]
        }.then{ lookupData -> Promise<Any> in
            // print(lookupData)
            
            // let error = lookupData["error"] as? NSObject
            let result = lookupData["result"] as? NSObject
            // print("error is", error is NSNull, result is NSNull)
            
            if(result is NSNull){
                // var (newKeyAssign, newKeyAssignSeal) = Promise<Any>.pending()
                
                // Assign key to the user and return (wraped in a promise)
                return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<String> in
                    print("keyAssign", data)
                    // Do keylookup again
                    return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                }.then{ data -> Promise<Any> in
                    print("keylookup", data)
                    let jsonlookupData = try JSONSerialization.jsonObject(with: Data(data.utf8)) as! [String : Any]
                    return Promise<Any>.value(jsonlookupData["result"] as Any)
                }
            }else{
                return Promise<Any>.value(lookupData["result"] as Any)
            }
        }.done{ data in
            // Convert the reponse to Promise<T>
            
            // print("done", data)
            guard let keys = data as? [String: [[String:String]]] else {throw "type casting for keys failed"}
            let currentKey = keys["keys"]![0]
            if(!isExtended){
                seal.fulfill(["address": currentKey["address"]!])
            }else{
                seal.fulfill(currentKey)
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
                
                if(decoded.error != nil) {throw "decoding error"}
                
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
                print(err)
                // seal.reject(err)
            }
        }
        return tempPromise
    }
    
    func retreiveNodeShare(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String, nodeSignatures: [[String:String]]) -> Promise<[[String:String]?]>{
        let (tempPromise, seal) = Promise<[[String:String]?]>.pending()

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
        var receivedRequiredShares = false
        for (i, pr) in promisesArrayReq.enumerated(){
            pr.done{ data, response in
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                // print("share responses", decoded)
                
                let decodedResult = decoded.result as? [String:Any]
                let keyObj = decodedResult!["keys"] as? [[String:Any]]
                let publicKey = keyObj?[0]["PublicKey"] as! [String : String]
                ShareResponses[i] = publicKey
                
                // let publicKeyString = String(data: try JSONSerialization.data(withJSONObject: publicKey), encoding: .utf8)
                let lookupShares = ShareResponses.filter{ $0 != nil } // Nonnil elements
                let keyResult = self.thresholdSame(arr: lookupShares.map{$0}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                if(keyResult != nil && !receivedRequiredShares){
                    receivedRequiredShares = true
                    seal.fulfill(lookupShares)
                }else{
                    print("All public keys ain't matchin \(i)")
                    // return Promise.init(error: "All public keys ain't matchin \(i)")
                }
            }
        }
        return tempPromise
    }
    
    func retreiveShares(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String){
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
        
        print(privateKey?.toHexString(), publicKeyHex, pubKeyX, pubKeyY, tokenCommitment)
        
        commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX!, pubKeyY: pubKeyY!, timestamp: timestamp, tokenCommitment: tokenCommitment)
            .done{ data in
                let nodeSignatures = data
                
                var promisesArrayReq = Array<Promise<(data: Data, response: URLResponse)> >()
                for el in endpoints {
                    let rq = try! self.makeUrlRequest(url: el);
                    
                    // todo : look into hetrogeneous array encoding
                    let dataForRequest = ["jsonrpc": "2.0",
                                          "id":10,
                                          "method": "ShareRequest",
                                          "params": ["encrypted": "yes",
                                                     "item": [["verifieridentifier":verifier, "verifier_id": verifierParams["verifier_id"]!, "idtoken": idToken, "nodesignatures": nodeSignatures]]
                        ]
                        ] as [String : Any]
                    
                    let rpcdata = try JSONSerialization.data(withJSONObject: dataForRequest)
                    // print( String(data: rpcdata, encoding: .utf8)!)
                    promisesArrayReq.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
                }
                
                var ShareResponses = Array<[String:String]?>.init(repeating: nil, count: promisesArrayReq.count)
                var receivedRequiredShares = false
                for (i, pr) in promisesArrayReq.enumerated(){
                    pr.then{ data, response -> Promise<JSONRPCresponse> in
                        let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                        // print("share responses", decoded)
                        
                        let decodedResult = decoded.result as? [String:Any]
                        let keyObj = decodedResult!["keys"] as? [[String:Any]]
                        let publicKey = keyObj?[0]["PublicKey"] as! [String : String]
                        ShareResponses[i] = publicKey
                        
                        // let publicKeyString = String(data: try JSONSerialization.data(withJSONObject: publicKey), encoding: .utf8)
                        let lookupShares = ShareResponses.filter{ $0 != nil } // Nonnil elements
                        let keyResult = self.thresholdSame(arr: lookupShares.map{$0}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                        if(keyResult != nil && !receivedRequiredShares){
                            receivedRequiredShares = true
                            return Promise<JSONRPCresponse>.value(decoded)
                        }else{
                            return Promise.init(error: "All public keys ain't matchin \(i)")
                        }
                    }.done{ data in
                        var testArr = "b5e2bb9a2c5025445dad60ff64f4bc4ea2217e92bb406e14077e7fb2b7d98c6256e32a39bf5215340240df018059abee0503716c972bedd868d5c366e3a409d3".hexa
                        var newtest = testArr.prefix(32)
                        newtest.reverse()
                        //        print(newtest)
                        
                        var newTest2 = testArr.suffix(32)
                        newTest2.reverse()
                        
                        newtest.append(contentsOf: newTest2)
                        //print(newtest)
                        
                        
                        var ephemPubKey = secp256k1_pubkey.init(data: self.array32toTuple(Array(newtest)))
                        var sharedSecret = self.ecdh(pubKey: ephemPubKey, privateKey: Data.init(hexString: "a615f79a8a1fc577bfb04ae7a7c2a381a3b081ec2fecf3df56e40893f4c5c7fd")!)
                        var sharedSecretData = sharedSecret!.data
                        var sharedSecretPrefix = self.tupleToArray(sharedSecretData).prefix(32)
                        var reversedSharedSecret = sharedSecretPrefix.reversed()
                        print(reversedSharedSecret.hexa)
                        //        print(tupleToArray(sharedSecretData).)
                        
                        // let prefix = sharedSecretData.prefix(32)
                        //        print("sharedSecretData", sharedSecretData)
                        var newXValue = reversedSharedSecret.hexa
                        
                        
                        var hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
                        let AesEncryptionKey = hash.prefix(64)
                        let iv1 = "0a041a50c1950c7a3268fff1b70c32ca".hexa
                        let share1 = "ZTE1OTkyN2E0MjgxZTY4NzQ0MWYyZTBmZjU5ZjNmM2YxZDIxMjEwZjhhYWIwYzQ0MWZiYjkxOGFhMjg3NGVmODY2MTAxZGM0ZTVjYTVhYzhlMDg0NzQyNzBkYzA0OTU4".fromBase64()!.hexa
                        // print("hash", hash)
                        
                        do{
                            let aes = try! AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv1), padding: .pkcs7)
                            //let encrypt = try! aes.encrypt(share1)
                            // print("encrypt", encrypt.hexa)
                            
                            
                            let decrypt = try! aes.decrypt(share1)
                            print("decrypt", decrypt.hexa)
                            
                        }catch CryptoSwift.AES.Error.dataPaddingRequired{
                            print("padding error")
                        }
                    }
                }
                
        }.catch{
            err in print(err)
        }
    }
}
