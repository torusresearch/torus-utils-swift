import Foundation

public class SessionToken: Codable {
    public let token: String
    public let signature: String
    public let node_pubx: String
    public let node_puby: String

    internal init(token: String, signature: String, node_pubx: String, node_puby: String) {
        self.token = token
        self.signature = signature
        self.node_pubx = node_pubx
        self.node_puby = node_puby
    }
}
