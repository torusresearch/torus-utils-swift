import Foundation
import BigInt

public struct TorusKey {
    public struct FinalKeyData {
        let evmAddress: String
        let X: String
        let Y: String
        let privKey: String?
    }

    public struct OAuthKeyData {
        let evmAddress: String
        let X: String
        let Y: String
        let privKey: String
    }

    public struct SessionData {
        let sessionTokenData: [SessionToken]
        let sessionAuthKey: String
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
