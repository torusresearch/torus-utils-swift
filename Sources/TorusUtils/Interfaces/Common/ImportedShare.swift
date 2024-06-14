import BigInt
import Foundation

internal struct ImportedShare: Codable {
    let oauth_pub_key_x: String
    let oauth_pub_key_y: String
    let final_user_point: Point
    let signing_pub_key_x: String
    let signing_pub_key_y: String
    let encryptedShare: String
    let encryptedShareMetadata: EciesHexOmitCiphertext
    let encryptedSeed: String?
    let node_index: Int
    let key_type: TorusKeyType
    let nonce_data: String
    let nonce_signature: String

    public init(oauth_pub_key_x: String, oauth_pub_key_y: String, final_user_point: Point, signing_pub_key_x: String, signing_pub_key_y: String, encryptedShare: String, encryptedShareMetadata: EciesHexOmitCiphertext, encryptedSeed: String? = nil, node_index: Int, key_type: TorusKeyType = .secp256k1, nonce_data: String, nonce_signature: String) {
        self.oauth_pub_key_x = oauth_pub_key_x
        self.oauth_pub_key_y = oauth_pub_key_y
        self.final_user_point = final_user_point
        self.signing_pub_key_x = signing_pub_key_x
        self.signing_pub_key_y = signing_pub_key_y
        self.encryptedShare = encryptedShare
        self.encryptedShareMetadata = encryptedShareMetadata
        self.encryptedSeed = encryptedSeed
        self.node_index = node_index
        self.key_type = key_type
        self.nonce_data = nonce_data
        self.nonce_signature = nonce_signature
    }
}
