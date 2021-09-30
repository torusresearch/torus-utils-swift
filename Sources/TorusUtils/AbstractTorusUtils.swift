//
//  File.swift
//  
//
//  Created by Shubham on 1/8/21.
//

import Foundation
import PromiseKit
import FetchNodeDetails

/// A protoctol to be  implemented by any class that would like to provide their own`TorusUtils`. A default uimplementation is provided by `TorusUtils`.
public protocol AbstractTorusUtils {
    
    
    /// Set the expected public keys of the Torus nodes.
    func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePub>)
    
    /// Retrive shares from the torus nodes given a set of credentials, inculding the user's unique id and the user's token.
    /// - Returns: A dictionary that should contain at least a `privateKey` and a `publicAddress` field.
    func retrieveShares(endpoints : Array<String>, verifierIdentifier: String, verifierId:String, idToken: String, extraParams: Data) -> Promise<[String:String]>
    
    /// Retrive the public address of a user from the torus nodes, given the user's unique id.
    /// - Returns: A dictionary that should contain at least a `address` field.
    func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String, isExtended: Bool) -> Promise<[String:String]>
}
