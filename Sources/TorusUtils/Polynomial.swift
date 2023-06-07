import Foundation
import CryptoKit
import BigInt
import CryptorECC

typealias ShareMap = [String: Share]

public struct Polynomial {
    let polynomial: [BigInt]
    let ecCurve: EllipticCurve
    
    init(polynomial: [BigInt], ecCurve: EllipticCurve) {
        self.polynomial = polynomial
        self.ecCurve = ecCurve
    }
    
    func getThreshold() -> Int {
        return polynomial.count
    }
    
    func polyEval(x: BigInt) -> BigInt {
        var xi = BigInt(x)
        var sum = BigInt(0)
        sum += polynomial[0]
        for i in 1..<polynomial.count {
            let tmp = xi * polynomial[i]
            sum += tmp
            sum %= getOrderOfCurve()
            xi *= x
            xi %= getOrderOfCurve()
        }
        return sum
    }
    
    func generateShares(shareIndexes: [BNString]) -> ShareMap {
        let newShareIndexes = shareIndexes.map { index -> BigInt in
            if case .bn(let bigint) = index {
                return bigint
            } else if case .string(let str) = index {
                return BigInt(str, radix: 16)!
            }
            // 0 will never be returned if index is valid
            return BigInt(0)
        }

        var shares: ShareMap = [:]
        for x in 0..<newShareIndexes.count {
            let hexString = newShareIndexes[x].serialize().toHexString()
            shares[hexString] = Share(shareIndex: BNString.bn(newShareIndexes[x]), share: BNString.bn(polyEval(x: newShareIndexes[x])))
        }
        return shares
    }
    

}

public func getOrderOfCurve() -> BigInt {
   let orderHex = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"
   let order = BigInt(orderHex, radix: 16)!
   return order
}
