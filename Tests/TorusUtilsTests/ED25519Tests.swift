//
//  ED25519Tests.swift
//
//
//  Created by Eric McGary on 4/9/22.
//

import XCTest
@testable import TorusUtils

class ED25519Tests: XCTestCase {
    func testThatInvalidKeyThrows() throws {
        var thrownError: Error?

        XCTAssertThrowsError(try ED25591.getED25519Key(privateKey: "invalid")) {
            thrownError = $0
        }

        XCTAssertTrue(
            thrownError is TorusUtilError,
            "Unexpected error type: \(type(of: thrownError))"
        )

        // Verify that our error is equal to what we expect
        XCTAssertEqual(thrownError as? TorusUtilError, .invalidKeySize)
    }

    func testThatValidKeyReturnsEd25519KeyPair() throws {
        let keypair = try ED25591.getED25519Key(privateKey: "746869736b65797061697277696c6c67656e6572617465737563636573736675")

        XCTAssertEqual(keypair.pk, "3KzG2V7hN9ZcqxsNw1xYmjoGjkhAnPHaeA2a5gbjSq9ib8Du3v5DgE1nQCDT9gtNJwhsZYmt9qnVcn1TXfDXjwmE")
        XCTAssertEqual(keypair.sk, "J9e2xjw84srAeBRrxtM4mDAF3UskupFCecFjFvcXM4G")
    }
}
