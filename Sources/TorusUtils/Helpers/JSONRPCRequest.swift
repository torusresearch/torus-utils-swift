//
//  JSONRPCRequest.swift
//
//
//  Created by Shubham on 26/3/20.
//

import BigInt
import Foundation

import AnyCodable
public struct GetPublicAddressOrKeyAssignParams : Encodable {
    public var verifier : String
    public var verifier_id : String
    public var extended_verifier_id :String?
    public var one_key_flow : Bool
    public var fetch_node_index : Bool
}


public struct SignerResponse: Codable {
    public var torusNonce: String
    public var torusSignature: String
    public var torusTimestamp: String

    enum SignerResponseKeys: String, CodingKey {
        case torusNonce = "torus-nonce"
        case torusTimestamp = "torus-timestamp"
        case torusSignature = "torus-signature"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SignerResponseKeys.self)
        try container.encode(torusNonce, forKey: .torusNonce)
        try container.encode(torusSignature, forKey: .torusSignature)
        try container.encode(torusTimestamp, forKey: .torusTimestamp)
    }

    public init(torusNonce: String, torusTimestamp: String, torusSignature: String) {
        self.torusNonce = torusNonce
        self.torusTimestamp = torusTimestamp
        self.torusSignature = torusSignature
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SignerResponseKeys.self)
        let nonce: String = try container.decode(String.self, forKey: .torusNonce)
        let signature: String = try container.decode(String.self, forKey: .torusSignature)
        let timestamp: String = try container.decode(String.self, forKey: .torusTimestamp)
        self.init(torusNonce: nonce, torusTimestamp: timestamp, torusSignature: signature)
    }
}

public struct KeyAssignRequest: Encodable {
    public var id: Int = 10
    public var jsonrpc: String = "2.0"
    public var method: String = JRPC_METHODS.LEGACY_KEY_ASSIGN
    public var params: Any
    public var torusNonce: String
    public var torusSignature: String
    public var torusTimestamp: String

    enum KeyAssignRequestKeys: String, CodingKey {
        case id
        case jsonrpc
        case method
        case params
        case torusNonce = "torus-nonce"
        case torusTimestamp = "torus-timestamp"
        case torusSignature = "torus-signature"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: KeyAssignRequestKeys.self)
        try container.encode(id, forKey: .id)

        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)

        if let _ = params as? [String: String] {
            try container.encode(params as! [String: String], forKey: .params)
        }
        if let _ = params as? [String: [String: [String: String]]] {
            try container.encode(params as! [String: [String: [String: String]]], forKey: .params)
        }

        try container.encode(torusNonce, forKey: .torusNonce)
        try container.encode(torusTimestamp, forKey: .torusTimestamp)
        try container.encode(torusSignature, forKey: .torusSignature)
    }

    public init(params: Any, signerResponse: SignerResponse) {
        self.params = params
        torusNonce = signerResponse.torusNonce
        torusSignature = signerResponse.torusSignature
        torusTimestamp = signerResponse.torusTimestamp
    }
}


public indirect enum MixedValue: Codable {
    case integer(Int)
    case boolean(Bool)
    case string(String)
    case mixValue([String : MixedValue])
    case array([MixedValue])

    public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            }else if let value = try? container.decode(Int.self) {
                self = .integer(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode([String: MixedValue].self) {
                self = .mixValue(value)
            } else if let value = try? container.decode([MixedValue].self) {
                self = .array(value)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed value")
            }
        }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let value) :
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .mixValue(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

/// JSON RPC request structure for serialization and deserialization purposes.
public struct JSONRPCrequest <T:Encodable>: Encodable {
    public var jsonrpc: String = "2.0"
    public var method: String
    public var params: T
    public var id: Int = 10

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case method
        case params
        case id
    }
}

public struct JSONRPCresponse: Decodable {
    public var id: Int
    public var jsonrpc = "2.0"
    public var result: Any?
    public var error: ErrorMessage?
    public var message: String?

    enum JSONRPCresponseKeys: String, CodingKey {
        case id
        case jsonrpc
        case result
        case error
        case errorMessage
    }

//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: JSONRPCresponseKeys.self)
//        try? container.encode(result as? MixedValue, forKey: .result)
////        try? container.encode(result as? [String: String], forKey: .result)
//        try container.encode(error, forKey: .error)
//    }

    public init(id: Int, jsonrpc: String, result: Decodable?, error: ErrorMessage?) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONRPCresponseKeys.self)
        let id: Int = try container.decode(Int.self, forKey: .id)
        let jsonrpc: String = try container.decode(String.self, forKey: .jsonrpc)
        let errorMessage = try container.decodeIfPresent(ErrorMessage.self, forKey: .error)
        if errorMessage != nil {
            self.init(id: id, jsonrpc: jsonrpc, result: nil, error: errorMessage)
            return
        }
        
        var result: Decodable?
        if let rawValue = try? container.decodeIfPresent(VerifierLookupResponse.self, forKey: .result){
            result = rawValue
        }else if let rawValue = try? container.decodeIfPresent(ShareRequestResult.self, forKey: .result){
            result = rawValue
        }else if let rawValue = try? container.decodeIfPresent(LegacyShareRequestResult.self, forKey: .result){
            result = rawValue
        }else if let rawValue = try? container.decodeIfPresent(CommitmentRequestResponse.self, forKey: .result){
            result = rawValue
        }else if let rawValue = try? container.decodeIfPresent(LegacyLookupResponse.self, forKey: .result){
            result = rawValue
        }else if let rawValue = try? container.decodeIfPresent(String.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(Int.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent(Bool.self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([Bool].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([Int].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: String].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: [[String: String]]].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: Int].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: [String: [String: String]]].self, forKey: .result) {
            result = rawValue
        } else if let rawValue = try? container.decodeIfPresent([String: [String: [String: [String: String?]]]].self, forKey: .result) {
            result = rawValue
        } else {
            result = nil
        }
        
        self.init(id: id, jsonrpc: jsonrpc, result: result, error: nil)
    }
}

public struct ErrorMessage: Codable {
    public var code: Int
    public var message: String
    public var data: String

    enum ErrorMessageKeys: String, CodingKey {
        case code
        case message
        case data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ErrorMessageKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(code, forKey: .code)
        try container.encode(data, forKey: .data)
    }
}
