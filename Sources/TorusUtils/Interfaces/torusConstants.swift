import Foundation
import BigInt

enum TORUS_SAPPHIRE_NETWORK_TYPE {
    case SAPPHIRE_DEVNET
    case SAPPHIRE_TESTNET
    case SAPPHIRE_MAINNET
}
struct TORUS_SAPPHIRE_NETWORK {
    static let SAPPHIRE_DEVNET = "sapphire_devnet"
    static let SAPPHIRE_TESTNET = "sapphire_testnet"
    static let SAPPHIRE_MAINNET = "sapphire_mainnet"
}


public class INodePub {
    let X: String
    let Y: String

    init(X: String, Y: String) {
        self.X = X
        self.Y = Y
    }
}

public class TorusPublicKey: INodePub {
    
    struct TorusPubNonce {
        let x: String
        let y: String
    }
    
    let address: String
    let metadataNonce: BigInt
    let pubNonce: TorusPubNonce?
    let upgraded: Bool?
    let nodeIndexes: [Int]

    init(X: String, Y: String, address: String, metadataNonce: BigInt, pubNonce: TorusPubNonce?, upgraded: Bool?, nodeIndexes: [Int]) {
        self.address = address
        self.metadataNonce = metadataNonce
        self.pubNonce = pubNonce
        self.upgraded = upgraded
        self.nodeIndexes = nodeIndexes
        super.init(X: X, Y: Y)
    }
}


