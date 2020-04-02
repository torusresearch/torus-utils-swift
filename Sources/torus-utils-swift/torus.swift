/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import fetch_node_details
import web3swift
import PromiseKit
import PMKFoundation
import CryptorECC

public class Torus{
    public var torusUtils : utils = utils()
    
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
                //var (newKeyAssign, newKeyAssignSeal) = Promise<Any>.pending()
                
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

        // print(publicKey, publicKeyHex, pubKeyX, pubKeyY, tokenCommitment)
        
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            let encoder = JSONEncoder()
            let rpcdata = try! encoder.encode(JSONRPCrequest(
                    method: "CommitmentRequest",
                    params: ["messageprefix": "mug00",
                             "tokencommitment": tokenCommitment,
                             "temppubx": pubKeyX!,
                             "temppuby": pubKeyY!,
                             "verifieridentifier":verifier,
                             "timestamp": timestamp]
            ))
            
            // print( String(data: rpcdata, encoding: .utf8)!)
            promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        
        // Array to store intermediate results
        var resultArray = Array<Any>.init(repeating: "nil", count: promisesArray.count)

        for (i, pr) in promisesArray.enumerated(){
            pr.then{ data, response -> Promise<JSONRPCresponse> in
                let encoder = JSONEncoder()
                let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                // print("response", decoded)
                if(decoded.error != nil) {throw "decoding error"}
                
                // check if k+t responses are back
                resultArray[i] = String(data: try encoder.encode(decoded), encoding: .utf8)
                let lookupShares = resultArray.filter{ $0 as? String != "nil" } // Nonnil elements
                if(lookupShares.count >= Int(endpoints.count/4)*3+1){
                    return Promise<JSONRPCresponse>.value(decoded)
                }
                else{
                    let errorJSONRPCResponse = JSONRPCresponse(id: 1, jsonrpc: "2.0", result: nil, error: nil)
                    return Promise<JSONRPCresponse>.value(errorJSONRPCResponse)
                }
                //let keyResult = self.thresholdSame(arr: lookupShares.map{$0 as! String}, threshold: Int(endpoints.count/4)*3+1) // Check if threshold is satisfied
                //print(keyResult)
                
            }.catch{
                err in print(err)
            }
        }
        
        
//
//        messageprefix: 'mug00',
//        tokencommitment: tokenCommitment.slice(2),
//        temppubx: pubKeyX,
//        temppuby: pubKeyY,
//        timestamp: (Date.now() - 2000).toString().slice(0, 10),
//        verifieridentifier: verifier,
        
    }
}
