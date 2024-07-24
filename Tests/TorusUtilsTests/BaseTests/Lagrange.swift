import BigInt
import Foundation
@testable import TorusUtils
import XCTest

class LagrangeTest: XCTestCase {
    var tu: TorusUtils!

    func testLagrangeInterpolatePolynomial() {
        let points: [Point] = [
            Point(x: BigInt(1), y: BigInt(2)),
            Point(x: BigInt(2), y: BigInt(5)),
            Point(x: BigInt(3), y: BigInt(10)),
        ]

        let polynomial = Lagrange.lagrangeInterpolatePolynomial(points: points)

        let xValues: [BigInt] = [BigInt(1), BigInt(2), BigInt(3)]
        let expectedYValues: [BigInt] = [BigInt(2), BigInt(5), BigInt(10)]

        for i in 0 ..< xValues.count {
            let x = xValues[i]
            let expectedY = expectedYValues[i]

            let y = polynomial.polyEval(x: x)

            XCTAssertEqual(y, expectedY)
        }
    }

    // TODO: Test other methods
}
