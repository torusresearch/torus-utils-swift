import Foundation

internal struct ShareRequestResult: Codable {
    let keys: [KeyAssignment]
    let sessionTokens: [String]
    let sessionTokenMetadata: [EciesHexOmitCiphertext]
    let sessionTokenSigs: [String]
    let sessionTokenSigMetadata: [EciesHexOmitCiphertext]
    let nodePubX: String
    let nodePubY: String
    let isNewKey: String
    let serverTimeOffset: String

    enum CodingKeys: CodingKey {
        case keys
        case session_tokens
        case session_token_metadata
        case session_token_sigs
        case session_token_sig_metadata
        case node_pubx
        case node_puby
        case is_new_key
        case server_time_offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keys, forKey: .keys)
        try container.encode(sessionTokens, forKey: .session_tokens)
        try container.encode(sessionTokenMetadata, forKey: .session_token_metadata)
        try container.encode(sessionTokenSigs, forKey: .session_token_sigs)
        try container.encode(sessionTokenSigMetadata, forKey: .session_token_sig_metadata)
        try container.encode(nodePubX, forKey: .node_pubx)
        try container.encode(nodePubX, forKey: .node_puby)
        try container.encode(isNewKey, forKey: .is_new_key)
        try container.encode(serverTimeOffset, forKey: .server_time_offset)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decode([KeyAssignment].self, forKey: .keys)
        nodePubX = try container.decode(String.self, forKey: .node_pubx)
        nodePubY = try container.decode(String.self, forKey: .node_puby)
        isNewKey = try container.decode(String.self, forKey: .is_new_key)

        if let sessionTokens = try? container.decodeIfPresent([String].self, forKey: .session_tokens) {
            self.sessionTokens = sessionTokens
        } else {
            sessionTokens = []
        }

        if let sessionTokenMetadata = try? container.decodeIfPresent([EciesHexOmitCiphertext].self, forKey: .session_token_metadata) {
            self.sessionTokenMetadata = sessionTokenMetadata
        } else {
            sessionTokenMetadata = []
        }

        if let sessionTokenSigs = try? container.decodeIfPresent([String].self, forKey: .session_token_sigs) {
            self.sessionTokenSigs = sessionTokenSigs
        } else {
            sessionTokenSigs = []
        }

        if let sessionTokenSigMetadata = try? container.decodeIfPresent([EciesHexOmitCiphertext].self, forKey: .session_token_sig_metadata) {
            self.sessionTokenSigMetadata = sessionTokenSigMetadata
        } else {
            sessionTokenSigMetadata = []
        }

        if let serverTimeOffset = try? container.decodeIfPresent(String.self, forKey: .server_time_offset) {
            self.serverTimeOffset = serverTimeOffset
        } else {
            serverTimeOffset = "0"
        }
    }
}
