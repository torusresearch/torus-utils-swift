import Foundation
import CryptoKit
import BigInt


struct BasePoint {
    let x: Data
    let y: Data
    
    public func add(_ other: BasePoint) -> BasePoint? {
        let x1 = self.x
        let y1 = self.y
        let x2 = other.x
        let y2 = other.y
        
        let bigX1 = BigInt(x1)
        let bigY1 = BigInt(y1)
        let bigX2 = BigInt(x2)
        let bigY2 = BigInt(y2)
        
        let sumX = (bigX1 + bigX2).serialize().toHexString().data(using: .utf8)!
        let sumY = (bigY1 + bigY2).serialize().toHexString().data(using: .utf8)!
        
        return BasePoint(x: sumX, y: sumY)
    }
    
    public func fromPublicKeyComponents(x: String, y: String) -> BasePoint {
        return BasePoint(x: Data(hex: x.addLeading0sForLength64()), y: Data(hex: y.addLeading0sForLength64()))
    }
}
