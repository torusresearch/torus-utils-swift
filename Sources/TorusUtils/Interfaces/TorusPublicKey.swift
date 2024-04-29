import BigInt
import Foundation

public class TorusPublicKey: Codable {
    public class OAuthKeyData: Codable {
        public let evmAddress: String
        public let X: String
        public let Y: String

        internal init(evmAddress: String, X: String, Y: String) {
            self.evmAddress = evmAddress
            self.X = X
            self.Y = Y
        }
    }

    public class FinalKeyData: Codable {
        public let evmAddress: String
        public let X: String
        public let Y: String

        internal init(evmAddress: String, X: String, Y: String) {
            self.evmAddress = evmAddress
            self.X = X
            self.Y = Y
        }
    }

    public class Metadata: Codable {
        public let pubNonce: PubNonce?
        public let nonce: BigUInt?
        public let typeOfUser: UserType
        public let upgraded: Bool?
        public let serverTimeOffset: Int

        internal init(pubNonce: PubNonce?, nonce: BigUInt?, typeOfUser: UserType, upgraded: Bool?, serverTimeOffset: Int) {
            self.pubNonce = pubNonce
            self.nonce = nonce
            self.typeOfUser = typeOfUser
            self.upgraded = upgraded
            self.serverTimeOffset = serverTimeOffset
        }
    }

    public class NodesData: Codable {
        public let nodeIndexes: [Int]

        internal init(nodeIndexes: [Int]) {
            self.nodeIndexes = nodeIndexes
        }
    }

    internal init(oAuthKeyData: OAuthKeyData?, finalKeyData: FinalKeyData?, metadata: Metadata?, nodesData: NodesData?) {
        self.finalKeyData = finalKeyData
        self.oAuthKeyData = oAuthKeyData
        self.metadata = metadata
        self.nodesData = nodesData
    }

    public let oAuthKeyData: OAuthKeyData?
    public let finalKeyData: FinalKeyData?
    public let metadata: Metadata?
    public let nodesData: NodesData?
}
