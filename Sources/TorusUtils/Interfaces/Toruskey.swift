import BigInt
import Foundation

public struct TorusKey {
    public struct FinalKeyData {
        public let evmAddress: String
        public let X: String
        public let Y: String
        public let privKey: String?
    }

    public struct OAuthKeyData {
        public let evmAddress: String
        public let X: String
        public let Y: String
        public let privKey: String
    }

    public struct SessionData {
        public let sessionTokenData: [SessionToken?]
        public let sessionAuthKey: String
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

    public init(finalKeyData: FinalKeyData?,
                oAuthKeyData: OAuthKeyData?,
                sessionData: SessionData?,
                metadata: Metadata?,
                nodesData: NodesData?) {
        self.finalKeyData = finalKeyData
        self.oAuthKeyData = oAuthKeyData
        self.sessionData = sessionData
        self.metadata = metadata
        self.nodesData = nodesData
    }

    public let finalKeyData: FinalKeyData?
    public let oAuthKeyData: OAuthKeyData?
    public let sessionData: SessionData?
    public let metadata: Metadata?
    public let nodesData: NodesData?
}


// allow response
public struct AllowSuccess : Codable {
    public let success: Bool
}

public struct AllowRejected : Codable {
    public let code: Int32
    public let error: String
    public let success: Bool
}

