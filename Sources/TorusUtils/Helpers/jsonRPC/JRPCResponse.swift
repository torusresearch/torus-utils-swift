import Foundation

internal struct AllowSuccess: Codable {
    public let success: Bool
}

internal struct AllowRejected: Codable {
    public let code: Int32
    public let error: String
    public let success: Bool
}

internal struct JRPCResponse<T: Codable>: Codable {
    public var id: Int
    public var jsonrpc = "2.0"
    public var result: T?
    public var error: ErrorMessage?
    public var message: String?

    enum JRPCResponseKeys: String, CodingKey {
        case id
        case jsonrpc
        case result
        case error
        case errorMessage
    }

    public init(id: Int, jsonrpc: String, result: T?, error: ErrorMessage?) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.result = result
        self.error = error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JRPCResponseKeys.self)
        let id: Int = try container.decode(Int.self, forKey: .id)
        let jsonrpc: String = try container.decode(String.self, forKey: .jsonrpc)
        let errorMessage = try container.decodeIfPresent(ErrorMessage.self, forKey: .error)
        if errorMessage != nil {
            self.init(id: id, jsonrpc: jsonrpc, result: nil, error: errorMessage)
            return
        }

        var result: T?
        if let rawValue = try? container.decodeIfPresent(T.self, forKey: .result) {
            result = rawValue
        }
        self.init(id: id, jsonrpc: jsonrpc, result: result, error: nil)
    }
}
