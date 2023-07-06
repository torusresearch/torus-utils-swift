import Foundation

struct ShareRequestResult : Decodable {
    let keys: [KeyAssignment]
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
        self.keys = try container.decode([KeyAssignment].self, forKey: .keys)
        self.sessionTokens = try container.decode([String].self, forKey: .session_tokens)
        self.sessionTokenMetadata = try container.decode([EciesHex].self, forKey: .session_token_metadata)
        self.sessionTokenSigs = try container.decode([String].self, forKey: .session_token_sigs)
        self.sessionTokenSigMetadata = try container.decode([EciesHex].self, forKey: .session_token_sig_metadata)
        self.nodePubX = try container.decode(String.self, forKey: .node_pubx )
        self.nodePubY = try container.decode(String.self, forKey: .node_puby)
    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: ShareRequestResult.self)
//        try? container.encode(sessionTokens , forKey: .session_tokens)
//
//    }
}

typealias ImportShareRequestResult = ShareRequestResult
