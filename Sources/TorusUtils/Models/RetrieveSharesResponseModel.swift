//
//  File.swift
//  
//
//  Created by Dhruv Jaiswal on 08/04/23.
//

import Foundation
import BigInt

public struct RetrieveSharesResponseModel {
    public let publicAddress: String
    public let privateKey: String
    public let nonce: BigUInt
    public let typeOfUser: TypeOfUser

    public init(publicKey: String, privateKey: String, nonce: BigUInt, typeOfUser: TypeOfUser) {
        self.publicAddress = publicKey
        self.privateKey = privateKey
        self.nonce = nonce
        self.typeOfUser = typeOfUser
    }
}
