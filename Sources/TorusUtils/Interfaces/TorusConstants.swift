import Foundation
import BigInt
import CommonSources

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

public class INodePub{
    let X: String
    let Y: String

    init(X: String, Y: String) {
        self.X = X
        self.Y = Y
    }
}

public func TorusNodePubModelToINodePub (node: TorusNodePubModel) -> INodePub {
    return INodePub( X: node.getX(), Y: node.getY() )
}
