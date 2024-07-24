import Foundation

internal struct GetMetadataResponse: Codable {
    public var message: String

    public init(message: String) {
        self.message = message
    }
}
