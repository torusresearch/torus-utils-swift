import Foundation
import XCTest
@testable import TorusUtils

class SigningTest: XCTestCase {
    func test_signing() throws {
        let key = SECP256K1.generatePrivateKey()!
        var pk = SECP256K1.privateKeyToPublicKey(privateKey: key)!
        let hash = try JSONEncoder().encode("{hello World}").sha3(.keccak256)
        let sig = SECP256K1.signForRecovery(hash: hash, privateKey: key).serializedSignature!
        
        let recover = SECP256K1.recoverPublicKey(hash: hash, signature: sig)!
        let ss = SECP256K1.serializePublicKey(publicKey: &pk, compressed: false)
        XCTAssertEqual(ss, recover)
    }
}
