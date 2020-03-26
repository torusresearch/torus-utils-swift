//
//  JSONRPCRequest.swift
//  
//
//  Created by Shubham on 26/3/20.
//

import Foundation

/// JSON RPC request structure for serialization and deserialization purposes.
public struct JSONRPCrequest: Encodable {
    public var jsonrpc: String = "2.0"
    public var method: String
    public var params: [String: String]
    public var id: Int = Int.random(in: 0 ... 10)
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case method
        case params
        case id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)
        try container.encode(params, forKey: .params)
        try container.encode(id, forKey: .id)
        
    }
}
