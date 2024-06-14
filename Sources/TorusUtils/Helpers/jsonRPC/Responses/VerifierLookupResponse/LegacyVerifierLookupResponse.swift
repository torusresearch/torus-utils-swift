import Foundation

internal struct LegacyVerifierLookupResponse: Codable {
    public struct Key: Codable {
        let pub_key_X: String
        let pub_key_Y: String
        let address: String

        init(pub_key_X: String, pub_key_Y: String, address: String) {
            self.pub_key_X = pub_key_X
            self.pub_key_Y = pub_key_Y
            self.address = address
        }

        enum JSONRPCresponseKeys: String, CodingKey {
            case pub_key_X
            case pub_key_Y
            case address
        }

        public init(from: Decoder) throws {
            let container = try from.container(keyedBy: CodingKeys.self)
            pub_key_X = try container.decode(String.self, forKey: .pub_key_X)
            pub_key_Y = try container.decode(String.self, forKey: .pub_key_Y)
            address = try container.decode(String.self, forKey: .address)
        }
    }

    var keys: [Key]
    var server_time_offset: String?

    public init(keys: [Key], serverTimeOffset: String? = nil) {
        self.keys = keys
        server_time_offset = serverTimeOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decode([LegacyVerifierLookupResponse.Key].self, forKey: .keys)
        server_time_offset = try container.decodeIfPresent(String.self, forKey: .server_time_offset)
    }
}
