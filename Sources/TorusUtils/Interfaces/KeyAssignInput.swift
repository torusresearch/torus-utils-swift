import Foundation

public struct KeyIndex {
    let index: String
    let serviceGroupId: String
    let tag: keyIndexTag
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
