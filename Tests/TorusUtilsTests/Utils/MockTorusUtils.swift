//
//  File.swift
//
//
//  Created by Shubham on 2/8/21.
//

import FetchNodeDetails
import Foundation
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

    func retrieveShares(torusNodePubs: Array<TorusNodePubModel>, endpoints: Array<String>, verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> [String: String] {
        return [:]
    }

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressModel {
        return .init(address: "")
    }
    
    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool) async throws -> GetUserAndAddressModel {
        return .init(typeOfUser: .v1, address: "", x: "", y: "")
    }
    
    func getOrSetNonce(x: String, y: String, privateKey: String?, getOnly: Bool) async throws -> GetOrSetNonceResultModel {
        return GetOrSetNonceResultModel.init(typeOfUser: "v1")
    }
}
