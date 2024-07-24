import FetchNodeDetails
import Foundation

internal class INodePub {
    let X: String
    let Y: String

    init(X: String, Y: String) {
        self.X = X
        self.Y = Y
    }
}

internal func TorusNodePubModelToINodePub(nodes: [TorusNodePubModel]) -> [INodePub] {
    return nodes.map({ INodePub(X: $0.getX(), Y: $0.getY()) })
}
