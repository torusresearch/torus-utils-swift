//
//  File.swift
//  
//
//  Created by Shubham on 25/3/20.
//

import Foundation
import fetch_node_details
import PromiseKit
import PMKFoundation

extension Torus {
    
    func makeUrlRequest(url: String) throws -> URLRequest {
        var rq = URLRequest(url: URL(string: url)!)
        rq.httpMethod = "POST"
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        // rq.httpBody = try JSONEncoder().encode(obj)
        return rq
    }
    
    func thresholdSame(arr: Array<String>, threshold: Int) -> String?{
        // uprint(threshold)
        var hashmap = [String:Int]()
        for (i, value) in arr.enumerated(){
            if((hashmap[value]) != nil) {hashmap[value]! += 1}
            else { hashmap[value] = 1 }
            if (hashmap[value] == threshold){
                return value
            }
            // print(hashmap)
        }
        return nil
    }
    
    public func keyLookup(endpoints : Array<String>, verifier : String, verifierId : String) -> Promise<String>{
        
        let (tempPromise, seal) = Promise<String>.pending()
        // Create Array of Promises
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            let encoder = JSONEncoder()
            let rpcdata = try! encoder.encode(JSONRPCrequest(method: "VerifierLookupRequest", params: ["verifier":verifier, "verifier_id":verifierId]))
            //print( String(data: rpcdata, encoding: .utf8)!)
            promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        var resultArray = Array<Any>.init(repeating: "nil", count: promisesArray.count)
        
        
        for (i, pr) in promisesArray.enumerated() {
            pr.done{ data, response in
                // print("keyLookup", String(data: data, encoding: .utf8))
                let decoder = try? JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                let encoder = JSONEncoder()
                
                if #available(OSX 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
                    encoder.outputFormatting = .sortedKeys
                } else {
                    // Fallback on earlier versions
                    seal.reject("sorting keys unavailable")
                }
                
                // Check if 5 responses are in
                resultArray[i] = String(data: try encoder.encode(decoder), encoding: .utf8)! // Encode the result and error into string and push to array
                // print(resultArray[i])
                
                let lookupShares = resultArray.filter{ $0 as? String != "nil" } // Nonnil elements
                let keyResult = self.thresholdSame(arr: lookupShares.map{$0 as! String}, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                // let errorResult = self.thresholdSame(arr: lookupShares.map{$0 as! String}, threshold: Int(endpoints.count/2)+1)
                // print("threshold result", keyResult)
                
                if(keyResult != nil)  { seal.fulfill(keyResult!) }
            }.done{
                
            }.catch{error in
                if(i+1 == promisesArray.count){
                    seal.reject(error)
                }
            }
        }
        return tempPromise
    }
    
    public func keyAssign(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String) -> Promise<JSONRPCresponse> {
        
        let (tempPromise, resolver) = Promise<JSONRPCresponse>.pending()
        
        var newEndpoints = endpoints
        newEndpoints.shuffle()
        print("newEndpoints", newEndpoints)
        
        let serialQueue = DispatchQueue(label: "keyassign.serial.queue")
        let semaphore = DispatchSemaphore(value: 1)
        
        for (i, endpoint) in endpoints.enumerated() {
            serialQueue.async {
                
                // Wait for the signal
                semaphore.wait()
                
                let encoder = JSONEncoder()
                let SignerObject = JSONRPCrequest(method: "KeyAssign", params: ["verifier":verifier, "verifier_id":verifierId])
                // print(SignerObject)
                let rpcdata = try! encoder.encode(SignerObject)
                // print("rpcdata", String(data: rpcdata, encoding: .utf8))
                var request = try! self.makeUrlRequest(url:  "https://signer.tor.us/api/sign")
                request.addValue(torusNodePubs[i].getX(), forHTTPHeaderField: "pubKeyX")
                request.addValue(torusNodePubs[i].getY(), forHTTPHeaderField: "pubKeyY")
                
                firstly {
                    URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
                }.then{ data, response -> Promise<(data: Data, response: URLResponse)> in
                    // print("repsonse from signer", String(data: data, encoding: .utf8))
                    // Combine jsonData and rpcData
                    let jsonData = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    var request = try self.makeUrlRequest(url: endpoint)
                    
                    request.addValue(jsonData["torus-timestamp"] as! String, forHTTPHeaderField: "torus-timestamp")
                    request.addValue(jsonData["torus-nonce"] as! String, forHTTPHeaderField: "torus-nonce")
                    request.addValue(jsonData["torus-signature"] as! String, forHTTPHeaderField: "torus-signature")
                    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    // print(request.allHTTPHeaderFields)
                    return URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
                }.done{ data, response in
                    let decodedData = try! JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                    // print("response from node", String(data: data, encoding: .utf8))
                    // print(String(data: data, encoding: .utf8))
                    resolver.fulfill(decodedData)
                    
                    // Signal to start again
                    semaphore.signal()
                }.catch{ err in
                    // Reject only if reached the last point
                    if(i+1==endpoint.count) {
                        resolver.reject(err)
                    }
                    // Signal to start again
                    semaphore.signal()
                }
                
            }
        }
        return tempPromise
        
    }
}


//export const keyLookup = (endpoints, verifier, verifierId) => {
//  const lookupPromises = endpoints.map((x) =>
//    post(
//      x,
//      generateJsonRPCObject('VerifierLookupRequest', {
//        verifier,
//        verifier_id: verifierId.toString().toLowerCase(),
//      })
//    ).catch((_) => undefined)
//  )
//  return Some(lookupPromises, (lookupResults) => {
//    const lookupShares = lookupResults.filter((x) => x)
//    const errorResult = thresholdSame(
//      lookupShares.map((x) => x && x.error),
//      ~~(endpoints.length / 2) + 1
//    )
//    const keyResult = thresholdSame(
//      lookupShares.map((x) => x && x.result),
//      ~~(endpoints.length / 2) + 1
//    )
//    if (keyResult || errorResult) {
//      return Promise.resolve({ keyResult, errorResult })
//    }
//    return Promise.reject(new Error('invalid'))
//  }).catch((_) => undefined)
//}
