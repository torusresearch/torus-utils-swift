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
    
    func retreiveNodeShare(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String, nodeSignatures: [[String:String]]) -> Promise<[Int:[String:String]]>{
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
        var resultArrayObjects = Array<JSONRPCresponse?>.init(repeating: nil, count: promisesArrayReq.count)
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
                ShareResponses[i] = publicKey //For threshold
                //resultArrayObjects[i] = decoded
                resultArray[i] = ["iv": metadata["iv"]!, "ephermalPublicKey": metadata["ephemPublicKey"]!, "share": share]
                
                // let publicKeyString = String(data: try JSONSerialization.data(withJSONObject: publicKey), encoding: .utf8)
                let lookupShares = ShareResponses.filter{ $0 != nil } // Nonnil elements
                
                // Comparing dictionaries, so the order of keys doesn't matter
                let keyResult = self.thresholdSame(arr: lookupShares.map{$0}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                if(keyResult != nil && !receivedRequiredShares){
                    receivedRequiredShares = true
                    seal.fulfill(resultArray)
                }else{
                    print("All public keys ain't matchin \(i)")
                    // return Promise.init(error: "All public keys ain't matchin \(i)")
                }
            }.catch{ err in
                print(err)
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
        .then{ data -> Promise<[Int:[String:String]]> in
            return self.retreiveNodeShare(endpoints: endpoints, verifier: verifier, verifierParams: verifierParams, idToken: idToken, nodeSignatures: data)
        }.done{ data in
            print("data after retrieve shares", data)
        }.catch{
            err in print(err)
        }
    }
}
