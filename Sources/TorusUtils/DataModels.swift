//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 04/06/22.
//

import BigInt
import Foundation

public enum TypeOfUser: String {
    case v1
    case v2
}

public struct GetUserAndAddressModel {
    public var typeOfUser: TypeOfUser
    public var pubNonce: PubNonce?
    public var nonceResult: String?
    public var address: String
    public var x: String
    public var y: String
}

public struct GetPublicAddressModel {
    public var address: String
    public var typeOfUser: TypeOfUser?
    public var x: String?
    public var y: String?
    public var metadataNonce: BigUInt?
    public var pubNonce: PubNonce?
}

public struct GetOrSetNonceResultModel: Decodable {
    public var typeOfUser: String
    public var nonce: String?
    public var pubNonce: PubNonce?
    public var ifps: String?
    public var upgraded: Bool?
}

public struct PubNonce: Decodable {
    public var x: String
    public var y: String
}

public struct UserTypeAndAddressModel {
    public var typeOfUser: String
    public var nonce: BigInt?
    public var x: String
    public var y: String
    public var address: String
}

public struct MetadataParams: Codable {
    public struct SetData: Codable {
        public var data: String
        public var timestamp: String
    }

    public var namespace: String?
    public var pub_key_X: String
    public var pub_key_Y: String
    public var set_data: SetData
    public var signature: String
}
