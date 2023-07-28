//
//  File.swift
//  
//
//  Created by CW Lee on 30/06/2023.
//

import Foundation

public struct RetrieveSharesResponseModel {
     public let publicAddress: String
     public let privateKey: String

     public init(publicKey: String, privateKey: String) {
         self.publicAddress = publicKey
         self.privateKey = privateKey
     }
 }

// legacy
public struct RetrieveDecryptAndReconstuctResponseModel {
    public let iv: String
    public let ephemPublicKey: String
    public let share: String
    public let pubKeyX: String
    public let pubKeyY: String

    public init(iv: String, ephemPublicKey: String, share: String, pubKeyX: String, pubKeyY: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.share = share
        self.pubKeyX = pubKeyX
        self.pubKeyY = pubKeyY
    }
}
