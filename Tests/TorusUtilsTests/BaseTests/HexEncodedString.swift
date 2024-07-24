import Foundation
@testable import TorusUtils
import XCTest

class HexEndodedTest: XCTestCase {
    func testOddAndEvenStrings() throws {
        let odd = "6F6464".hexEncodedToString()
        let even = "6576656E".hexEncodedToString()
        let extra_zero_padded = "06576656E".hexEncodedToString()
        let double_padded = "00006576656E".hexEncodedToString()
        let unpadded = "56E".hexEncodedToString()

        XCTAssertEqual(odd, "odd") // 6F 64 64
        XCTAssertEqual(even, "even") // 65 76 65 6E
        XCTAssertEqual(extra_zero_padded, "even") // 00 65 76 65 6E
        XCTAssertEqual(double_padded, "even") // 00 00 65 76 65 6E
        XCTAssertEqual(unpadded, "\u{5}n") // 05 6E
    }
}
