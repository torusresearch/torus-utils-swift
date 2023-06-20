import Foundation

struct KeyLookupResult {
    let keyResult: VerifierLookupResponse.Key
    let nodeIndexes: [Int]
    let nonceResult: GetOrSetNonceResult?
}
