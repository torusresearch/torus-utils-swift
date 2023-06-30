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
