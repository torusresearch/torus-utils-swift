//
//  File.swift
//
//
//  Created by Shubham on 2/4/20.
//

import Foundation

public enum TorusUtilError: Error, Equatable {
    case configurationError
    case apiRequestFailed
    case errInResponse(Any)
    case encodingFailed(String? = nil)
    case decodingFailed(String? = nil)
    case commitmentRequestFailed
    case importShareFailed
    case decryptionFailed
    case thresholdError
    case promiseFulfilled
    case privateKeyDeriveFailed
    case timeout
    case missingNodePubKeyError
    case unableToDerive
    case interpolationFailed
    case nodesUnavailable
    case invalidKeySize
    case runtime(_ msg: String)
    case retrieveOrImportShareError
    case empty
}

extension TorusUtilError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .configurationError:
            return "SDK Configuration incorrect. Network is probably incorrect"
        case .apiRequestFailed:
            return "API request failed or No response from the node"
        case let .decodingFailed(response):
            return "JSON Decoding error \(response ?? "")"
        case let .errInResponse(str):
            return "API response error \(str)"
        case .decryptionFailed:
            return "Decryption Failed"
        case .commitmentRequestFailed:
            return "commitment request failed"
        case .importShareFailed:
            return "import share failed"
        case .thresholdError:
            return "Threshold error"
        case .promiseFulfilled:
            return "Promise fulfilled"
        case .privateKeyDeriveFailed:
            return "could not derive private key"
        case .timeout:
            return "Timeout"
        case .missingNodePubKeyError:
            return "Missing node pub key for node index"
        case .unableToDerive:
            return "could not derive private key"
        case .interpolationFailed:
            return "lagrange interpolation failed"
        case .nodesUnavailable:
            return "One or more nodes unavailable"
        case .empty:
            return ""
        case let .runtime(msg):
            return msg
        case .invalidKeySize:
            return "Invalid key size. Expected 32 bytes"
        case let .encodingFailed(msg):
            return "Could not encode data \(msg ?? "")"
        case .retrieveOrImportShareError:
            return "retrieve or import share failed"
        }
    }

    public static func == (lhs: TorusUtilError, rhs: TorusUtilError) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        let error1 = lhs as NSError
        let error2 = rhs as NSError
        return error1.debugDescription == error2.debugDescription && "\(lhs)" == "\(rhs)"
    }
}

extension TorusUtilError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configurationError:
            return "SDK Configuration incorrect. Network is probably incorrect"
        case .apiRequestFailed:
            return "API request failed or No response from the node"
        case let .decodingFailed(response):
            return "JSON Decoding error \(response ?? "")"
        case let .errInResponse(str):
            return "API response error \(str)"
        case .decryptionFailed:
            return "Decryption Failed"
        case .commitmentRequestFailed:
            return "commitment request failed"
        case .thresholdError:
            return "Threshold error"
        case .promiseFulfilled:
            return "Promise fulfilled"
        case .timeout:
            return "Timeout"
        case .unableToDerive:
            return "could not derive private key"
        case .interpolationFailed:
            return "lagrange interpolation failed"
        case .nodesUnavailable:
            return "One or more nodes unavailable"
        case .empty:
            return ""
        case let .runtime(msg):
            return msg
        case .invalidKeySize:
            return "Invalid key size. Expected 32 bytes"
        case let .encodingFailed(msg):
            return "Could not encode data \(msg ?? "")"
        default:
            return "default Error msg"
            
        }
    }
}
