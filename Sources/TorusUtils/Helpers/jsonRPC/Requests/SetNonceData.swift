import Foundation

internal struct SetNonceData: Codable {
    public var operation: String?
    public var data: String?
    public var timestamp: String?
    public var seed: String?

    public init(operation: String? = nil, data: String? = nil, timestamp: String? = nil, seed: String? = nil) {
        self.operation = operation
        self.data = data
        self.timestamp = timestamp
        self.seed = seed
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(operation, forKey: .operation)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        // There is a bug in the server that expects seed to be empty and not optional, when it checks signatures. It is optional in the interface though.
        if seed == nil {
            try container.encode("", forKey: .seed)
        } else {
            try container.encode(seed, forKey: .seed)
        }
    }
}
