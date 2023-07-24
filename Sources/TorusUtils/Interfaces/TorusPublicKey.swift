import Foundation
import BigInt

public enum UserType: String {
    case v1
    case v2
}

public struct TorusPublicKey {
    public struct FinalKeyData {
        let evmAddress: String
        let X: String
        let Y: String
    }

    public struct OAuthKeyData {
        let evmAddress: String
        let X: String
        let Y: String
    }

    public struct Metadata {
        let pubNonce: PubNonce?
        let nonce: BigUInt?
        let typeOfUser: UserType
        let upgraded: Bool?
    }

    public struct NodesData {
        let nodeIndexes: [Int]
    }
    
    public init (finalKeyData: FinalKeyData?, oAuthKeyData: OAuthKeyData?, metadata: Metadata?, nodesData: NodesData?) {
        self.finalKeyData = finalKeyData
        self.oAuthKeyData = oAuthKeyData
        self.metadata = metadata
        self.nodesData = nodesData
    }

    public let finalKeyData: FinalKeyData?
    public let oAuthKeyData: OAuthKeyData?
    public let metadata: Metadata?
    public let nodesData: NodesData? 
}

public typealias V2NonceResultType = GetOrSetNonceResult

struct V1NonceResultType {
    let typeOfUser: UserType
    let nonce: String?
}
