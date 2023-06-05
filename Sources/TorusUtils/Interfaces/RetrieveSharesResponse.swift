import Foundation

public struct RetrieveSharesResponse {
    public let publicAddress: String
    public let privateKey: String

    public init(publicKey: String, privateKey: String) {
        self.publicAddress = publicKey
        self.privateKey = privateKey
    }
}
