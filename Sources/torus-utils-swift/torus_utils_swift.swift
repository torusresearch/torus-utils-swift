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
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String) -> Promise<Void>{
        
        return Promise<Void>{ seal in
            self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId).done{ data in
                let data = try JSONSerialization.jsonObject(with: Data(data.utf8), options: .mutableContainers)
                print(data)
                seal.fulfill(())
            }
        }
        
    }
    
}
