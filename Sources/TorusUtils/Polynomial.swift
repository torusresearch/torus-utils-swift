import BigInt
import CryptoKit
import Foundation

typealias ShareMap = [String: Share]

public struct Polynomial {
    let polynomial: [BigInt]

    init(polynomial: [BigInt]) {
        self.polynomial = polynomial
    }

    func getThreshold() -> Int {
        return polynomial.count
    }

    func polyEval(x: BigInt) -> BigInt {
        var xi = BigInt(x)
        var sum = BigInt(0)
        sum += polynomial[0]
        for i in 1 ..< polynomial.count {
            let tmp = xi * polynomial[i]
            sum += tmp
            sum %= getOrderOfCurve()
            xi *= x
            xi %= getOrderOfCurve()
        }
        return sum
    }

    func generateShares(shareIndexes: [BigInt]) -> ShareMap {
        var shares: ShareMap = [:]
        for x in 0 ..< shareIndexes.count {
            let hexString = shareIndexes[x].serialize().toHexString()
            shares[hexString] = Share(shareIndex: shareIndexes[x], share: polyEval(x: shareIndexes[x]))
        }
        return shares
    }
}

public func getOrderOfCurve() -> BigInt {
    let orderHex = CURVE_N
    let order = BigInt(orderHex, radix: 16)!
    return order
}
