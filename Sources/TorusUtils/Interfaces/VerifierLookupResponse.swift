import Foundation

struct VerifierLookupResponse {
    struct Key {
        let pub_key_X: String
        let pub_key_Y: String
        let address: String
        let nonce_data: GetOrSetNonceResult?
        let created_at: Int?
    }
    
    let keys: [Key]
    let is_new_key: Bool
    let node_index: Int
}
