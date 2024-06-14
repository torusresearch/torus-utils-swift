import BigInt
import Foundation

typealias ShareMap = [String: Share]

internal struct Polynomial {
    let polynomial: [BigInt]

    init(polynomial: [BigInt]) {
        self.polynomial = polynomial
    }

    func getThreshold() -> Int {
        return polynomial.count
    }

    func polyEval(x: BigInt) -> BigInt {
        let tmpX = x
        var xi = BigInt(tmpX)
        var sum = BigInt(0)
        sum += polynomial[0]
        for i in 1 ..< polynomial.count {
            let tmp = (xi * polynomial[i])
            sum = (sum + tmp).modulus(KeyUtils.getOrderOfCurve())
            xi = (x * tmpX).modulus(KeyUtils.getOrderOfCurve())
        }
        return sum
    }

    func generateShares(shareIndexes: [BigInt]) -> ShareMap {
        var shares: ShareMap = [:]
        for x in 0 ..< shareIndexes.count {
            let hexString = shareIndexes[x].magnitude.serialize().hexString.addLeading0sForLength64()
            shares[hexString] = Share(shareIndex: shareIndexes[x], share: polyEval(x: shareIndexes[x]))
        }
        return shares
    }
}
