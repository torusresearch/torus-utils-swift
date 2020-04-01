/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import fetch_node_details
import web3swift
import PromiseKit
import PMKFoundation

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
            let error = lookupData["error"] as? NSObject
            let result = lookupData["result"] as? NSObject
            print("error is", error is NSNull, result is NSNull)
            
            if(result is NSNull){
                var (newpp, newppseal) = Promise<Any>.pending()
                self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<String> in
                    print("keyAssign", data)
                    return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                }.done{ data in
                    // print(data)
                    let jsonlookupData = try JSONSerialization.jsonObject(with: Data(data.utf8)) as! [String : Any]
                    newppseal.fulfill(Promise<Any>.value(jsonlookupData["result"]))
                }
                return newpp
            }else{
                return Promise<Any>.value(lookupData["result"])
            }
        }.then{ data -> Promise<[String:String]> in
            // Convert the reponse to Promise<T>
            
            print("done", data as? [String: [[String:String]]])
            guard let keys = data as? [String: [[String:String]]] else {throw "type casting for keys failed"}
            guard let currentKey = keys["keys"]![0] as? [String:String] else {throw "type casting for currentkey failed"}
            if(isExtended){
                return Promise<[String:String]>.value(["address": currentKey["address"]!])
            }else{
                return Promise<[String:String]>.value(currentKey)
            }
        }.catch{err in
            print("err", err)
        }
        return tempPromise

    }
}

//self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
//           .map{ lookupData in
//               try JSONSerialization.jsonObject(with: Data(lookupData.utf8)) as! [String : Any]
//       }.then{ lookupData in
//           let error = lookupData["error"] as? String
//           print(error)
//           if(error != nil){
//               return Promise<[String: Any]>.value(lookupData)
//               //                    self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<String> in
//               //                        print("keyAssign", data)
//               //                        return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
//               //                    }.done{ data -> Void in
//               //                        print(data)
//               //                        let jsonlookupData = try JSONSerialization.jsonObject(with: Data(data.utf8)) as! [String : Any]
//               //                        return Promise<[String: Any]>.value(jsonlookupData)
//               //
//               //                        // seal.fulfill(data)
//               //                    }.catch{err in
//               //                        seal.reject(err)
//               //                    }
//           }else{
//               return Promise<[String: Any]>.value(lookupData)
//           }
//       }.done{ data in
//           print(data)
//           seal.fulfill("asdf")
//       }.catch{ err in
//           seal.reject(err)
//       }
