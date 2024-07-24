import Foundation

internal struct ShareRequestParams: Codable {
    public struct ShareRequestItem: Codable {
        public var verifieridentifier: String
        public var verifier_id: String?
        public var extended_verifier_id: String?
        public var idtoken: String
        public var nodesignatures: [CommitmentRequestResult?]
        public var pub_key_x: String?
        public var pub_key_y: String?
        public var signing_pub_key_x: String?
        public var signing_pub_key_y: String?
        public var encrypted_share: String?
        public var encrypted_share_metadata: EciesHexOmitCiphertext?
        public var node_index: Int?
        public var key_type: TorusKeyType?
        public var nonce_data: String?
        public var nonce_signature: String?
        public var sub_verifier_ids: [String]?
        public var session_token_exp_second: Int?
        public var verify_params: [VerifyParams?]?
        public var sss_endpoint: String?
        
        // TODO: This is a bit of a mess from here due to legacy reasons and should be cleaned up in future.
        // Note: Nil values by default are excluded from serialization
        public var enable_verifier_id_hash: Bool? // most
        public var app_s: String? // meta
        public var app_id: String? // meta
        public var domain: String? // farcaster
        public var nonce: String? // farcaster
        public var message: String? // farcaster
        public var signature: String? // farcaster, passkey, webauthn
        public var clientDataJson: String? // passkey, webauthn
        public var authenticatorData: String? // passkey, webauthn
        public var publicKey: String? // passkey, webauthn
        public var challenge: String? // passkey, webauthn
        public var rpOrigin: String? // passkey, webauthn
        public var rpId: String? // passkey, webauthn
        public var jwk_endpoint: String? // passkey, jwt
        public var default_node_set: [String]? // passkey, jwt
        public var jwt_verifier_id_field: String? // passkey, jwt
        public var jwt_verifier_id_case_sensitive: Bool? // passkey, jwt
        public var jwk_keys: String? // passkey, jwt
        public var jwt_validation_fields: [String]? // passkey, jwt
        public var jwt_validation_values: [String]? // passkey, jwt
        public var index: Int? // demo
        public var email: String? // demo
        public var id: String? // test, jwt, passkey
        public var correct_id_token: String? // test
        public var verify_param: String? // OrAggregate
        public var threshold: Int? // SingleID
        public var pub_k_x: String? // Signature
        public var pub_k_y: String? // Signature
    }

    public var encrypted: String = "yes"
    public var item: [ShareRequestItem]
    public var use_temp: Bool = true
    public var distributed_metadata: Bool = true
    public var one_key_flow: Bool = true
    public var client_time: String
}
