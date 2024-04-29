import Foundation

internal struct KeyLookupResult {
    public struct KeyResult: Codable {
        public var keys: [VerifierLookupResponse.Key]
        public var is_new_key: Bool

        public init(keys: [VerifierLookupResponse.Key], is_new_key: Bool) {
            self.keys = keys
            self.is_new_key = is_new_key
        }

        public init(is_new_key: Bool) {
            keys = []
            self.is_new_key = is_new_key
        }
    }

    public let keyResult: KeyResult?
    public let nodeIndexes: [Int]
    public let serverTimeOffset: Int
    public let nonceResult: GetOrSetNonceResult?
    public let errorResult: ErrorMessage?

    public init(keyResult: KeyResult?, nodeIndexes: [Int], serverTimeOffset: Int, nonceResult: GetOrSetNonceResult?, errorResult: ErrorMessage?) {
        self.keyResult = keyResult
        self.nodeIndexes = nodeIndexes
        self.serverTimeOffset = serverTimeOffset
        self.nonceResult = nonceResult
        self.errorResult = errorResult
    }
}
