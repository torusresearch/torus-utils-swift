import Foundation

/// JSON RPC request structure for serialization and deserialization purposes.
internal struct JRPCRequest<T: Encodable>: Encodable {
    public var jsonrpc: String = "2.0"
    public var method: String
    public var params: T
    public var id: Int = 10

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case method
        case params
        case id
    }
}
