import Foundation
import BigInt

public struct RetrieveSharesResponse {
    public let ethAddress: String
    public let privKey: String
    public let sessionTokenData: [SessionToken]
    public let X: String
    public let Y: String
    public let metadataNonce: BigInt
    public let postboxPubKeyX: String
    public let postboxPubKeyY: String
    public let sessionAuthKey: String
    public let nodeIndexes: [Int]
    
    public init(ethAddress: String, privKey: String, sessionTokenData: [SessionToken], X: String, Y: String, metadataNonce: BigInt, postboxPubKeyX: String, postboxPubKeyY: String, sessionAuthKey: String, nodeIndexes: [Int]) {
        self.ethAddress = ethAddress
        self.privKey = privKey
        self.sessionTokenData = sessionTokenData
        self.X = X
        self.Y = Y
        self.metadataNonce = metadataNonce
        self.postboxPubKeyX = postboxPubKeyX
        self.postboxPubKeyY = postboxPubKeyY
        self.sessionAuthKey = sessionAuthKey
        self.nodeIndexes = nodeIndexes
    }
}
