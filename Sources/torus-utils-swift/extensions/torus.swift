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
    
    public func keyLookup(endpoints : Array<String>, verifier : String, verifierId : String){
        
    }
    
    public func keyAssign(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub> , lastPoint : Int?, firstPoint : Int?, verifier : String, verifierId : String) throws -> Promise<String> {
        
        // Handle Recursion params
        var nodeNum : Int, initialPoint : Int
        if (lastPoint == nil) {
            nodeNum = Int((Float.random(in: 0 ..< 1) * Float(endpoints.count)).rounded(.down))
            initialPoint = nodeNum
        } else {
            nodeNum = lastPoint! % endpoints.count
        }
        if (nodeNum == firstPoint!) { throw "Looped through all" }
        if (firstPoint == nil) { initialPoint = firstPoint! }
        
        let returnPromise = Promise<String>{ seal in
            let encoder = JSONEncoder()
            let rpcdata = try encoder.encode(JSONRPCrequest(method: "keyAssign", params: ["verifier":verifier, "verifierId":verifierId]))
            
            var request = try makeUrlRequest(url:  "https://signer.tor.us/api/sign")
            request.httpMethod = "POST"
            request.addValue(torusNodePubs[nodeNum].getX(), forHTTPHeaderField: "pubKeyX")
            request.addValue(torusNodePubs[nodeNum].getY(), forHTTPHeaderField: "pubKeyY")
            
            
            firstly {
                URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
            }.then{ data, response -> Promise<(data: Data, response: URLResponse)> in
                
                print(data, response)
                
                var jsonData = try JSONSerialization.jsonObject(with: data)
                var request = try self.makeUrlRequest(url:  endpoints[nodeNum])
                request.httpMethod = "POST"
                // Combine jsonData and rpcData
                return URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
            }.done{ data, response in
                seal.fulfill("ASDF")
            }.catch{ err in
                seal.reject(err)
            }
        }
        return returnPromise
        
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
