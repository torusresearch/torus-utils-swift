//
//  File.swift
//
//
//  Created by Shubham on 2/8/21.
//

import FetchNodeDetails
import Foundation
import TorusUtils
import BigInt

class MockTorusUtils: AbstractTorusUtils {

    var nodePubKeys: [TorusNodePubModel]

    init() {
        nodePubKeys = []
    }

    func setTorusNodePubKeys(nodePubKeys: [TorusNodePubModel]) {
        self.nodePubKeys = nodePubKeys
    }

    func retrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponseModel {
        return .init(publicKey: "", privateKey: "", nonce: BigUInt(0), typeOfUser: .v1)
    }

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressModel {
        return .init(address: "")
    }

    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool) async throws -> GetUserAndAddressModel {
        return .init(typeOfUser: .v1, address: "", x: "", y: "")
    }

    func getOrSetNonce(x: String, y: String, privateKey: String?, getOnly: Bool) async throws -> GetOrSetNonceResultModel {
        return GetOrSetNonceResultModel.init(typeOfUser: "v1")
    }
    
    func getPostBoxKey(torusKey: RetrieveSharesResponseModel) -> String {
        return ""
    }
}
