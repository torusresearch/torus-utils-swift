import Foundation

public struct VerifierParams {
    public let verifier_id: String
    public let extended_verifier_id: String?
    public let additionalParams: [String: Any]
    
    init(verifier_id: String, extended_verifier_id: String? = nil, additionalParams: [String: Any] = [:]) {
        self.verifier_id = verifier_id
        self.extended_verifier_id = extended_verifier_id
        self.additionalParams = additionalParams
    }
}
