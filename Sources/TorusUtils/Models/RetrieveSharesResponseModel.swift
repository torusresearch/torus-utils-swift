//
//  File.swift
//  
//
//  Created by Dhruv Jaiswal on 08/04/23.
//

import Foundation

public struct RetrieveSharesResponseModel {
    public let publicAddress:String
    public let privateKey:String

    public init(publicKey: String, privateKey: String) {
        self.publicAddress = publicKey
        self.privateKey = privateKey
    }
}
