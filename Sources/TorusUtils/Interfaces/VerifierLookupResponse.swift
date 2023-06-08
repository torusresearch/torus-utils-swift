import Foundation

struct VerifierLookupResponse {
    struct Key {
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
        
        init(pub_key_X: String, pub_key_Y: String, address: String) {
            self.init(pub_key_X: pub_key_X, pub_key_Y: pub_key_Y, address: address, nonce_data: nil, created_at: nil)
        }
    }
    
    var keys: [Key]?
    var is_new_key: Bool
    var node_index: Int
}
