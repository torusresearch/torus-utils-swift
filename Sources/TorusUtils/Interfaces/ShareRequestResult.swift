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
        self.nodePubX = try container.decode(String.self, forKey: .node_pubx )
        self.nodePubY = try container.decode(String.self, forKey: .node_puby)
        
        if let sessionTokens = try? container.decodeIfPresent([String].self, forKey: .session_tokens) {
            self.sessionTokens = sessionTokens
        } else {
            self.sessionTokens = []
        }
        
        if let sessionTokenMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_metadata) {
            self.sessionTokenMetadata = sessionTokenMetadata
        } else {
            self.sessionTokenMetadata = []
        }
        
        if let sessionTokenSigs = try? container.decodeIfPresent([String].self, forKey: .session_token_sigs) {
            self.sessionTokenSigs = sessionTokenSigs
        } else {
            self.sessionTokenSigs = []
        }
        
        if let sessionTokenSigMetadata = try? container.decodeIfPresent([EciesHex].self, forKey: .session_token_sig_metadata) {
            self.sessionTokenSigMetadata = sessionTokenSigMetadata
        } else {
            self.sessionTokenSigMetadata = []
        }
        
    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: ShareRequestResult.self)
//        try? container.encode(sessionTokens , forKey: .session_tokens)
//
//    }
}

typealias ImportShareRequestResult = ShareRequestResult
