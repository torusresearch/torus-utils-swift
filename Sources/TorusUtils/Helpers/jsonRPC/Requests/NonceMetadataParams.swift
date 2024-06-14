import Foundation

internal struct NonceMetadataParams {
    public var namespace: String?
    public var pub_key_X: String
    public var pub_key_Y: String
    public var set_data: SetNonceData
    public var key_type: TorusKeyType
    public var signature: String
    public var encodedData: String
    public var seed: String?

    public init(pub_key_X: String, pub_key_Y: String, setData: SetNonceData, encodedData: String, signature: String, namespace: String? = nil, key_type: TorusKeyType = .secp256k1, seed: String? = nil) {
        self.namespace = namespace
        self.pub_key_X = pub_key_X
        self.pub_key_Y = pub_key_Y
        set_data = setData
        self.signature = signature
        self.seed = seed
        self.key_type = key_type
        self.encodedData = encodedData
    }
}
