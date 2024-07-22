import Foundation

// TODO: This class is a bit of a mess for legacy reasons and should be cleaned up in future.

public class TorusUtilsExtraParams: Codable {
    var enable_verifier_id_hash: Bool? // most
    var app_s: String? // meta
    var app_id: String? // meta
    var domain: String? // farcaster
    var nonce: String? // farcaster
    var message: String? // farcaster
    var signature: String? // farcaster, passkey, webauthn
    var clientDataJson: String? // passkey, webauthn
    var authenticatorData: String? // passkey, webauthn
    var publicKey: String? // passkey, webauthn
    var challenge: String? // passkey, webauthn
    var rpOrigin: String? // passkey, webauthn
    var rpId: String? // passkey, webauthn
    var jwk_endpoint: String? // passkey, jwt
    var default_node_set: [String]? // passkey, jwt
    var jwt_verifier_id_field: String? // passkey, jwt
    var jwt_verifier_id_case_sensitive: Bool? // passkey, jwt
    var jwk_keys: String? // passkey, jwt
    var jwt_validation_fields: [String]? // passkey, jwt
    var jwt_validation_values: [String]? // passkey, jwt
    var index: Int? // demo
    var email: String? // demo
    var id: String? // test, jwt, passkey
    var correct_id_token: String? // test
    var verify_param: String? // OrAggregate
    var session_token_exp_second: Int?
    var threshold: Int? // SingleID
    var pub_k_x: String? // Signature
    var pub_k_y: String? // Signature
    
    public init() {}
    
    public init(enable_verifier_id_hash: Bool? = nil, app_s: String? = nil, app_id: String? = nil, domain: String? = nil, nonce: String? = nil, message: String? = nil, signature: String? = nil, clientDataJson: String? = nil, authenticatorData: String? = nil, publicKey: String? = nil, challenge: String? = nil, rpOrigin: String? = nil, rpId: String? = nil, jwk_endpoint: String? = nil, default_node_set: [String]? = nil, jwt_verifier_id_field: String? = nil, jwt_verifier_id_case_sensitive: Bool? = nil, jwk_keys: String? = nil, jwt_validation_fields: [String]? = nil, jwt_validation_values: [String]? = nil, index: Int? = nil, email: String? = nil, id: String? = nil, correct_id_token: String? = nil, verify_param: String? = nil, session_token_exp_second: Int? = nil, threshold: Int? = nil, pub_k_x: String? = nil, pub_k_y: String? = nil) {
        self.enable_verifier_id_hash = enable_verifier_id_hash
        self.app_s = app_s
        self.app_id = app_id
        self.domain = domain
        self.nonce = nonce
        self.message = message
        self.signature = signature
        self.clientDataJson = clientDataJson
        self.authenticatorData = authenticatorData
        self.publicKey = publicKey
        self.challenge = challenge
        self.rpOrigin = rpOrigin
        self.rpId = rpId
        self.jwk_endpoint = jwk_endpoint
        self.default_node_set = default_node_set
        self.jwt_verifier_id_field = jwt_verifier_id_field
        self.jwt_verifier_id_case_sensitive = jwt_verifier_id_case_sensitive
        self.jwk_keys = jwk_keys
        self.jwt_validation_fields = jwt_validation_fields
        self.jwt_validation_values = jwt_validation_values
        self.index = index
        self.email = email
        self.id = id
        self.correct_id_token = correct_id_token
        self.verify_param = verify_param
        self.session_token_exp_second = session_token_exp_second
        self.threshold = threshold
        self.pub_k_x = pub_k_x
        self.pub_k_y = pub_k_y
    }
}
