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

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<[String: String]> {
        return Promise.value([:])
    }
}
