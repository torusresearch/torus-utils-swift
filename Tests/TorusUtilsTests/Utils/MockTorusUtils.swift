//
//  File.swift
//
//
//  Created by Shubham on 2/8/21.
//

import FetchNodeDetails
import Foundation
import PromiseKit
import TorusUtils
@testable import TorusUtils

class MockTorusUtils: AbstractTorusUtils {
  
    
    
    var nodePubKeys: Array<TorusNodePubModel>

    init() {
        nodePubKeys = []
    }

    func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePubModel>) {
        self.nodePubKeys = nodePubKeys
    }

    func retrieveShares(endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String: String]> {
        return Promise.value([:])
    }

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<GetPublicAddressModel> {
        return Promise.value(.init(address: ""))
    }
    
    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool) -> Promise<GetUserAndAddressModel> {
        return Promise.value(.init(typeOfUser: .v1, address: "", x: "", y: ""))
    }
    
    func getOrSetNonce(x: String, y: String, privateKey: String?, getOnly: Bool) -> Promise<GetOrSetNonceResultModel> {
        return Promise.value(GetOrSetNonceResultModel.init(typeOfUser: "v1"))
    }
}
