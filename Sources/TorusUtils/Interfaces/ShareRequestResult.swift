import Foundation

struct ShareRequestResult: Decodable {
    let keys: [KeyAssignment]
    let sessionTokens: [String]
    let sessionTokenMetadata: [EciesHex]
    let sessionTokenSigs: [String]
    let sessionTokenSigMetadata: [EciesHex]
    let nodePubX: String
    let nodePubY: String
    let isNewKey: String

    enum CodingKeys: CodingKey {
        case keys
        case session_tokens
        case session_token_metadata
        case session_token_sigs
        case session_token_sig_metadata
        case node_pubx
        case node_puby
        case is_new_key
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

        if let sessionTokenMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_metadata) {
            self.sessionTokenMetadata = sessionTokenMetadata
        } else {
            sessionTokenMetadata = []
        }

        if let sessionTokenSigs = try? container.decodeIfPresent([String].self, forKey: .session_token_sigs) {
            self.sessionTokenSigs = sessionTokenSigs
        } else {
            sessionTokenSigs = []
        }

        if let sessionTokenSigMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_sig_metadata) {
            self.sessionTokenSigMetadata = sessionTokenSigMetadata
        } else {
            sessionTokenSigMetadata = []
        }
    }
}

typealias ImportShareRequestResult = ShareRequestResult

struct LegacyShareRequestResult: Decodable {
    let keys: [LegacyKeyAssignment]
    let sessionTokens: [String]
    let sessionTokenMetadata: [EciesHex]
    let sessionTokenSigs: [String]
    let sessionTokenSigMetadata: [EciesHex]
    let nodePubX: String
    let nodePubY: String

    enum CodingKeys: CodingKey {
        case keys
        case session_tokens
        case session_token_metadata
        case session_token_sigs
        case session_token_sig_metadata
        case node_pubx
        case node_puby
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decode([LegacyKeyAssignment].self, forKey: .keys)
        nodePubX = try container.decode(String.self, forKey: .node_pubx)
        nodePubY = try container.decode(String.self, forKey: .node_puby)

        if let sessionTokens = try? container.decodeIfPresent([String].self, forKey: .session_tokens) {
            self.sessionTokens = sessionTokens
        } else {
            sessionTokens = []
        }

        if let sessionTokenMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_metadata) {
            self.sessionTokenMetadata = sessionTokenMetadata
        } else {
            sessionTokenMetadata = []
        }

        if let sessionTokenSigs = try? container.decodeIfPresent([String].self, forKey: .session_token_sigs) {
            self.sessionTokenSigs = sessionTokenSigs
        } else {
            sessionTokenSigs = []
        }

        if let sessionTokenSigMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_sig_metadata) {
            self.sessionTokenSigMetadata = sessionTokenSigMetadata
        } else {
            sessionTokenSigMetadata = []
        }
    }
}
