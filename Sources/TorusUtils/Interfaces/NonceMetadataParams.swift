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
    let pubKeyX: String
    let pubKeyY: String
    let setData: PartialSetNonceData
    let signature: String
}

