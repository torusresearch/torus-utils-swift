import BigInt
import Foundation
import XCTest

@testable import TorusUtils
class LagrangeTest: XCTestCase {
    var tu: TorusUtils!

    func testLagrangeInterpolatePolynomial() {
        let points: [Point] = [
            Point(x: BigInt(1), y: BigInt(2)),
            Point(x: BigInt(2), y: BigInt(5)),
            Point(x: BigInt(3), y: BigInt(10)),
        ]

        let polynomial = lagrangeInterpolatePolynomial(points: points)

        let xValues: [BigInt] = [BigInt(1), BigInt(2), BigInt(3)]
        let expectedYValues: [BigInt] = [BigInt(2), BigInt(5), BigInt(10)]

        for i in 0 ..< xValues.count {
            let x = xValues[i]
            let expectedY = expectedYValues[i]

            let y = polynomial.polyEval(x: x)

            assert(y == expectedY, "Point (\(x), \(y)) does not match the expected value of (\(x), \(expectedY)).")
        }

        print("All assertions passed.")
    }
}
