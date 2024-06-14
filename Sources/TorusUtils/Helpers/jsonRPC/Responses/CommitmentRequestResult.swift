import Foundation

internal struct CommitmentRequestResult: Codable {
    public var signature: String
    public var data: String
    public var nodepubx: String
    public var nodepuby: String
    public var nodeindex: String

    public init(data: String, nodepubx: String, nodepuby: String, signature: String, nodeindex: String) {
        self.data = data
        self.nodepubx = nodepubx
        self.nodepuby = nodepuby
        self.signature = signature
        self.nodeindex = nodeindex
    }
}
