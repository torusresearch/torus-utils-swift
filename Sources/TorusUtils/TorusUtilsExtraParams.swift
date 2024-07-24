import Foundation

// TODO: This class is a bit of a mess for legacy reasons and should be cleaned up in future.

public class TorusUtilsExtraParams: Codable {
    var nonce: String? // farcaster
    var message: String? // farcaster
    var signature: String? // farcaster, passkey, webauthn
    var clientDataJson: String? // passkey, webauthn
    var authenticatorData: String? // passkey, webauthn
    var publicKey: String? // passkey, webauthn
    var challenge: String? // passkey, webauthn
    var rpOrigin: String? // passkey, webauthn
    var rpId: String? // passkey, webauthn
    var session_token_exp_second: Int?
    var timestamp: Int? // Signature
    
    public init() {}
    
    public init(nonce: String? = nil, message: String? = nil, signature: String? = nil, clientDataJson: String? = nil, authenticatorData: String? = nil, publicKey: String? = nil, challenge: String? = nil, rpOrigin: String? = nil, rpId: String? = nil, session_token_exp_second: Int? = nil, timestamp: Int? = nil) {
        self.nonce = nonce
        self.message = message
        self.signature = signature
        self.clientDataJson = clientDataJson
        self.authenticatorData = authenticatorData
        self.publicKey = publicKey
        self.challenge = challenge
        self.rpOrigin = rpOrigin
        self.rpId = rpId
        self.session_token_exp_second = session_token_exp_second
        self.timestamp = timestamp
    }
}
