import Foundation
import CryptoKit
import BigInt

struct Share {
    let x: BigInt
    let y: BigInt
    
    init(x: Data, y: Data) {
        self.x = BigInt(data: x)
        self.y = BigInt(data: y)
    }
}

struct Polynomial {
    let polynomial: [BigInt]
    let ecCurve: ECCurve
    
    init(polynomial: [BigInt], ecCurve: ECCurve) {
        self.polynomial = polynomial
        self.ecCurve = ecCurve
    }
    
    func getThreshold() -> Int {
        return polynomial.count
    }
    
    func polyEval(x: Data) -> BigInt {
        let tmpX = BigInt(data: x)
        var xi = tmpX
        var sum = BigInt(0)
        sum += polynomial[0]
        
        for i in 1..<polynomial.count {
            let tmp = xi * polynomial[i]
            sum += tmp
            sum = sum % ecCurve.curveOrder
            xi *= tmpX
            xi = xi % ecCurve.curveOrder
        }
        
        return sum
    }
    
    func generateShares(shareIndexes: [Data]) -> [String: Share] {
        let newShareIndexes: [BigInt] = shareIndexes.map { index in
            if let intValue = Int(String(data: index, encoding: .hexadecimal)!) {
                return BigInt(intValue)
            }
            return BigInt(data: index)
        }
        
        var shares: [String: Share] = [:]
        for x in 0..<newShareIndexes.count {
            let indexString = String(data: newShareIndexes[x].serialize(), encoding: .hexadecimal)!
            shares[indexString] = Share(x: newShareIndexes[x], y: polyEval(x: newShareIndexes[x].serialize()))
        }
        
        return shares
    }
}

struct ECCurve {
    let curveOrder: BigInt
    
    init(curveOrder: Data) {
        self.curveOrder = BigInt(data: curveOrder)
    }
}
