import Foundation

public struct SetNonceData {
    let operation: String
    let data: String
    let timestamp: String
}

public struct PartialSetNonceData {
    let operation: String?
    let data: String?
    let timestamp: String?
}

public struct NonceMetadataParams {
    let namespace: String?
    let pub_key_X: String
    let pub_key_Y: String
    let set_data: PartialSetNonceData
    let signature: String
}

