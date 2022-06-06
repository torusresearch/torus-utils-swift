//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 04/06/22.
//

import BigInt
import FetchNodeDetails
import Foundation
import OSLog
import PromiseKit
import secp256k1
import SwiftUI
import web3

public enum TypeOfUser: String {
    case v1
    case v2
}

public struct GetUserAndAddressModel {
    var typeOfUser: TypeOfUser
    var pubNonce: PubNonce?
    var nonceResult: String?
    var address: String
    var x: String
    var y: String
}

public struct GetPublicAddressModel {
    var address: String
    var typeOfUser: TypeOfUser?
    var x: String?
    var y: String?
    var metadataNonce: BigUInt?
    var pubNonce: PubNonce?
}

public struct GetOrSetNonceResultModel: Decodable {
    var typeOfUser: String
    var nonce: String?
    var pubNonce: PubNonce?
    var ifps: String?
    var upgraded: Bool?
}

public struct PubNonce: Decodable {
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
        var timestamp: String
    }

    var namespace: String?
    var pub_key_X: String
    var pub_key_Y: String
    var set_data: SetData
    var signature: String
}
