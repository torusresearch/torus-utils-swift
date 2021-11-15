//
//  File.swift
//  
//
//  Created by Shubham on 2/8/21.
//

import Foundation
import TorusUtils
import PromiseKit
import FetchNodeDetails

class MockTorusUtils: AbstractTorusUtils{
    var nodePubKeys: Array<TorusNodePub>
    
    init(){
        self.nodePubKeys = []
    }
    
    func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePub>) {
        self.nodePubKeys = nodePubKeys
    }
    
    func retrieveShares(endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String : String]> {
        return Promise.value([:])
    }
    
    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePub>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<[String : String]> {
        return Promise.value([:])
    }
    
    
}
