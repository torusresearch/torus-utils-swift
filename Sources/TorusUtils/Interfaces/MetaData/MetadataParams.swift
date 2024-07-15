import Foundation

internal struct MetadataParams: Codable {
    public struct SetData: Codable {
        public var data: String // "getNonce" || "getOrSetNonce" || String
        public var timestamp: String

        public init(data: String, timestamp: String) {
            self.data = data
            self.timestamp = timestamp
        }
    }

    public var namespace: String?
    public var pub_key_X: String
    public var pub_key_Y: String
    public var key_type: TorusKeyType?
    public var set_data: SetData
    public var signature: String

    public init(pub_key_X: String, pub_key_Y: String, setData: SetData, signature: String, namespace: String? = nil, keyType: TorusKeyType? = nil) {
        self.namespace = namespace
        self.pub_key_X = pub_key_X
        self.pub_key_Y = pub_key_Y
        key_type = keyType
        set_data = setData
        self.signature = signature
    }
}
