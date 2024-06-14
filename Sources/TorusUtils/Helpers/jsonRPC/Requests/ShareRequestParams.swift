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
        // [key: string]; This should be strongly typed
        public var sub_verifier_ids: [String]?
        public var session_token_exp_second: Int?
        public var verify_params: [VerifyParams?]?
        public var sss_endpoint: String?
    }

    public var encrypted: String = "yes"
    public var item: [ShareRequestItem]
    public var use_temp: Bool = true
    public var distributed_metadata: Bool = true
    public var one_key_flow: Bool = true
    public var client_time: String
}
