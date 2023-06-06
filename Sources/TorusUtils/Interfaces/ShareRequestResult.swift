import Foundation

struct ShareRequestResult {
    let keys: [KeyAssignment]
    let sessionTokens: [String]
    let sessionTokenMetadata: [EciesHex]
    let sessionTokenSigs: [String]
    let sessionTokenSigMetadata: [EciesHex]
    let nodePubX: String
    let nodePubY: String
}

typealias ImportShareRequestResult = ShareRequestResult
