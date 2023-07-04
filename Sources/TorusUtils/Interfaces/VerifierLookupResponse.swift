import Foundation

struct VerifierLookupResponse : Codable {
    struct Key : Codable {
        let pub_key_X: String
        let pub_key_Y: String
        let address: String
        let nonce_data: GetOrSetNonceResult?
        let created_at: Int?
        
        init(pub_key_X: String, pub_key_Y: String, address: String, nonce_data: GetOrSetNonceResult? = nil, created_at: Int? = nil) {
            self.pub_key_X = pub_key_X
            self.pub_key_Y = pub_key_Y
            self.address = address
            self.nonce_data = nonce_data
            self.created_at = created_at
        }
        
        enum JSONRPCresponseKeys: String, CodingKey {
            case pub_key_X
            case pub_key_Y
            case address
            case nonce_data
            case created_at
        }
        
        init(pub_key_X: String, pub_key_Y: String, address: String) {
            self.init(pub_key_X: pub_key_X, pub_key_Y: pub_key_Y, address: address, nonce_data: nil, created_at: nil)
        }
        
        public init(from: Decoder) throws {
            let container = try from.container(keyedBy: CodingKeys.self)
            pub_key_X = try container.decode(String.self, forKey: .pub_key_X)
            pub_key_Y = try container.decode(String.self, forKey: .pub_key_Y)
            address = try container.decode(String.self, forKey: .address)
            nonce_data = try? container.decodeIfPresent(GetOrSetNonceResult.self, forKey: .nonce_data)
            created_at = try? container.decodeIfPresent(Int.self, forKey: .created_at)
        }
    }
    
    var keys: [Key]?
    var is_new_key: Bool
    var node_index: Int
    
    public init(keys: [Key]?, is_new_key: Bool, node_index: Int) {
        self.keys = keys
        self.is_new_key = is_new_key
        self.node_index = node_index
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keys = try container.decodeIfPresent([VerifierLookupResponse.Key].self, forKey: .keys)
        self.is_new_key = try container.decode(Bool.self, forKey: .is_new_key)
        self.node_index = try container.decode(Int.self, forKey: .node_index)
    }
    
}
