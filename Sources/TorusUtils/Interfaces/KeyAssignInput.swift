import Foundation

public struct KeyIndex: Decodable {
    let index: String
    let serviceGroupId: String
    let tag: String

    enum CodingKeys: CodingKey {
        case index
        case service_group_id
        case tag
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(String.self, forKey: .index)
        serviceGroupId = try container.decode(String.self, forKey: .service_group_id)
        tag = try container.decode(String.self, forKey: .tag)
    }
}

enum keyIndexTag: String {
    case imported
    case generated
}

public struct KeyAssignInput {
    let endpoints: [String]
    let torusNodePubs: [INodePub]
    let lastPoint: Int?
    let firstPoint: Int?
    let verifier: String
    let verifierId: String
    let signerHost: String
    let network: String
    let clientId: String
}

public struct KeyAssignment: Decodable {
    let index: String
    let publicKey: PublicKey
    let threshold: Int
    let nodeIndex: Int
    let share: String
    let shareMetadata: EciesHex
    let nonceData: GetOrSetNonceResult?

    struct PublicKey: Hashable, Codable {
        let X: String
        let Y: String
    }

    enum CodingKeys: CodingKey {
        case index
        case public_key
        case threshold
        case node_index
        case share
        case share_metadata
        case nonce_data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(String.self, forKey: .index)

        publicKey = try container.decode(PublicKey.self, forKey: .public_key)
        threshold = Int(try container.decode(String.self, forKey: .threshold))!
        nodeIndex = Int(try container.decode(String.self, forKey: .node_index))!
        share = try container.decode(String.self, forKey: .share)
        shareMetadata = try container.decode(EciesHex.self, forKey: .share_metadata)
        nonceData = try container.decodeIfPresent(GetOrSetNonceResult.self, forKey: .nonce_data)
    }
}

public struct LegacyKeyAssignment: Decodable {
    let index: String
    let publicKey: PublicKey
    let threshold: String
    let verifiers: [String: [String]]
    let share: String
    let metadata: EciesHex

    struct PublicKey: Hashable, Codable {
        let X: String
        let Y: String
    }

    enum CodingKeys: CodingKey {
        case Index
        case PublicKey
        case Threshold
        case Verifiers
        case Share
        case Metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(String.self, forKey: .Index)
        publicKey = try container.decode(PublicKey.self, forKey: .PublicKey)
        threshold = try container.decode(String.self, forKey: .Threshold)
        verifiers = try container.decode([String: [String]].self, forKey: .Verifiers)
        share = try container.decode(String.self, forKey: .Share)
        metadata = try container.decode(EciesHex.self, forKey: .Metadata)
    }
}
