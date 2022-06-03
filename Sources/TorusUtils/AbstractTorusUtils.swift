//
//  File.swift
//
//
//  Created by Shubham on 1/8/21.
//

import BigInt
import FetchNodeDetails
import Foundation
import PromiseKit

public protocol AbstractTorusUtils {
    func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePubModel>)

    func retrieveShares(endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String: String]>

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool)  -> Promise<[String: String]>
}



public struct GetOrSetNonceResultModel: Decodable {

    var typeOfUser: String
    var nonce: String?
    var pubNonce: PubNonce?
    var ifps: String?
    var upgraded: Bool?

   
}
struct PubNonce: Decodable {
    var x: String
    var y: String
}

public struct UserTypeAndAddressModel {
    var typeOfUser: String
    var nonce: BigInt?
    var x: String
    var y: String
    var address: String
}

public struct MetadataParams: Codable {
    struct SetData: Codable {
        var data: String
        var timeStamp: String
    }

    var namespace: String?
    var pub_key_X: String
    var pub_key_Y: String
    var setData: SetData
    var signature: String
}

public struct V2UserTypeAndAddress {
    var typeOfUser: String
    var nonce: BigInt?
    var pubNonce: TorusNodePubModel
    var ifps: String?
    var upgraded: Bool?
    var x: String
    var y: String
    var address: String
}
