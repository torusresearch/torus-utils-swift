import Foundation
import BigInt

public enum UserType: String {
    case v1
    case v2
}

public struct TorusPublicKey {
    public struct FinalKeyData {
        public let evmAddress: String
        public let X: String
        public let Y: String
    }

    public struct OAuthKeyData {
        public let evmAddress: String
        public let X: String
        public let Y: String
    }

    public struct Metadata {
        public let pubNonce: PubNonce?
        public let nonce: BigUInt?
        public let typeOfUser: UserType
        public let upgraded: Bool?
    }

    public struct NodesData {
        public let nodeIndexes: [Int]
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
