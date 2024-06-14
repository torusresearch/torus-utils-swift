import Foundation

internal struct ErrorMessage: Codable {
    public var code: Int
    public var message: String
    public var data: String

    enum ErrorMessageKeys: String, CodingKey {
        case code
        case message
        case data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ErrorMessageKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(code, forKey: .code)
        try container.encode(data, forKey: .data)
    }
}
