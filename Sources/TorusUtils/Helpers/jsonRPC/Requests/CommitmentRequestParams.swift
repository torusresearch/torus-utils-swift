import Foundation

internal struct CommitmentRequestParams: Codable {
    public var messageprefix: String
    public var tokencommitment: String
    public var temppubx: String
    public var temppuby: String
    public var verifieridentifier: String
    public var timestamp: String?
}
