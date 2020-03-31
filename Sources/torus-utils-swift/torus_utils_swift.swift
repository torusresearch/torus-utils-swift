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
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String) -> Promise<String>{
        
         let (returnPromise, seal) = Promise<Void>.pending()
//        self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId).map{ data in
//            try JSONSerialization.jsonObject(with: Data(data.utf8)) as! [String : Any]
//        }.then{ data in
//            print(data)
//            return Promise<String>.value("asdf")
//        }
        
        return Promise<String>{ seal in

            self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
            .map{ lookupData in
                try JSONSerialization.jsonObject(with: Data(lookupData.utf8)) as! [String : Any]
            }.then{ lookupData in
                let error = lookupData["error"] as? String
                print(error)
                if(error != nil){
                    return Promise<[String: Any]>.value(lookupData)
//                    self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<String> in
//                        print("keyAssign", data)
//                        return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
//                    }.done{ data -> Void in
//                        print(data)
//                        let jsonlookupData = try JSONSerialization.jsonObject(with: Data(data.utf8)) as! [String : Any]
//                        return Promise<[String: Any]>.value(jsonlookupData)
//
//                        // seal.fulfill(data)
//                    }.catch{err in
//                        seal.reject(err)
//                    }
                }else{
                    return Promise<[String: Any]>.value(lookupData)
                }
            }.done{ data in
                print(data)
                seal.fulfill("asdf")
            }.catch{ err in
                seal.reject(err)
            }
        }


    }
    
}
