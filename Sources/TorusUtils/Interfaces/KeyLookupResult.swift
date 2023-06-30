import Foundation

struct KeyLookupResult {
    let keyResult: KeyLookupResponse
    let nodeIndexes: [Int]
    let nonceResult: GetOrSetNonceResult?
}
