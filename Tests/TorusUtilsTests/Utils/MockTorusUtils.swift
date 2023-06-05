//
//  File.swift
//
//
//  Created by Shubham on 2/8/21.
//

import FetchNodeDetails
import Foundation
import TorusUtils

class MockTorusUtils: AbstractTorusUtils {

    var nodePubKeys: [TorusNodePubModel]

    init() {
        nodePubKeys = []
    }

    func setTorusNodePubKeys(nodePubKeys: [TorusNodePubModel]) {
        self.nodePubKeys = nodePubKeys
    }

    func retrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponse {
        return .init(publicKey: "", privateKey: "")
    }

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressResult {
        return .init(address: "")
    }

    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool) async throws -> GetUserAndAddress {
        return .init(typeOfUser: .v1, address: "", x: "", y: "")
    }

    func getOrSetNonce(x: String, y: String, privateKey: String?, getOnly: Bool) async throws -> GetOrSetNonceResult {
        return GetOrSetNonceResult.init(typeOfUser: "v1")
    }
}
