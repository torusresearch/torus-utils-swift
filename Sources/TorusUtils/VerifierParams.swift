import Foundation

public class VerifyParams: Codable {
    public var verifier_id: String?
    public var idtoken: String?

    public init(verifier_id: String?, idtoken: String?) {
        self.verifier_id = verifier_id
        self.idtoken = idtoken
    }
}

public class VerifierParams {
    // [key: string]: unknown; This should be strongly typed
    public let verifier_id: String
    public let extended_verifier_id: String?
    public let sub_verifier_ids: [String]?
    public let verify_params: [VerifyParams]?

    public init(verifier_id: String, extended_verifier_id: String? = nil, sub_verifier_ids: [String]? = nil, verify_params: [VerifyParams]? = nil) {
        self.verifier_id = verifier_id
        self.extended_verifier_id = extended_verifier_id
        self.sub_verifier_ids = sub_verifier_ids
        self.verify_params = verify_params
    }
}
