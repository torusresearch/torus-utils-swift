import Foundation
@testable import TorusUtils
import XCTest

class EtherTest: XCTestCase {
    func testPublicToEtherAddress() throws {
        let fullAddress = String("04238569d5e12caf57d34fb5b2a0679c7775b5f61fd18cd69db9cc600a651749c3ec13a9367380b7a024a67f5e663f3afd40175c3223da63f6024b05d0bd9f292e")
        let (X, Y) = try KeyUtils.getPublicKeyCoords(pubKey: fullAddress)
        let etherAddress = try KeyUtils.generateAddressFromPubKey(publicKeyX: X, publicKeyY: Y)
        let finalAddress = "0x048975d4997D7578A3419851639c10318db430b6"
        XCTAssertEqual(etherAddress, finalAddress)
    }
}
