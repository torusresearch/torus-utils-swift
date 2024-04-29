import Foundation
@testable import TorusUtils
import XCTest

class Combinations: XCTestCase {
    func test_kCombinations() throws {
        let input = [0, 1, 2, 3, 4, 5]
        let zero = kCombinations(elements: input.slice, k: 0)
        XCTAssertEqual(zero, [])
        let greater = kCombinations(elements: input.slice, k: 10)
        XCTAssertEqual(greater, [])
        let equal = kCombinations(elements: input.slice, k: 6)
        XCTAssertEqual(equal, [[0, 1, 2, 3, 4, 5]])
        let one = kCombinations(elements: input.slice, k: 1)
        XCTAssertEqual(one, [[0], [1], [2], [3], [4], [5]])
        let two = kCombinations(elements: input.slice, k: 2)
        XCTAssertEqual(two, [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5],
            [1, 2], [1, 3], [1, 4], [1, 5],
            [2, 3], [2, 4], [2, 5],
            [3, 4], [3, 5],
            [4, 5],
        ])
        let input2 = [1, 2, 3, 4, 5]
        let next = kCombinations(elements: input2.slice, k: 3)
        XCTAssertEqual(next, [
            [1, 2, 3],
            [1, 2, 4],
            [1, 2, 5],
            [1, 3, 4],
            [1, 3, 5],
            [1, 4, 5],
            [2, 3, 4],
            [2, 3, 5],
            [2, 4, 5],
            [3, 4, 5],
        ])
    }
}
