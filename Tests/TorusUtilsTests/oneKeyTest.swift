//
//  oneKey.swift
//
//
//  Created by Dhruv Jaiswal on 02/06/22.
//

import BigInt
import CryptorECC
import CryptoSwift
import FetchNodeDetails
import JWTKit
import PromiseKit
import secp256k1
import web3
import XCTest

import CoreMedia
@testable import TorusUtils

class OneKeyTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: FetchNodeDetails!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
        fnd = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = true) async -> AllNodeDetailsModel {
        return await withCheckedContinuation { continuation in
            _ = fnd.getNodeDetails(verifier: verifer, verifierID: veriferID).done { [unowned self] nodeDetails in
                tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), enableOneKey: enableOneKey)
                continuation.resume(returning: nodeDetails)
            }.catch({ error in
                fatalError(error.localizedDescription)
            })
        }
    }

    func test_fetch_public_address() async {
        let exp1 = XCTestExpectation(description: "should still fetch v1 public address correctly")
        let verifier = "google-lrc"
        let verifierID = TORUS_TEST_EMAIL
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: true).done { val in
            XCTAssertEqual(val.address, "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
            // XCTAssertEqual(val["typeOfUser"], TypeOfUser.v1.rawValue)
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_login() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer).done { data in
            XCTAssertEqual(data["privateKey"], "068ee4f97468ef1ae95d18554458d372e31968190ae38e377be59d8b3c9f7a25")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_aggregate_login() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: hashedIDToken, extraParams: buffer).done { data in
            XCTAssertEqual(data["publicAddress"], "0xE1155dB406dAD89DdeE9FB9EfC29C8EedC2A0C8B")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 30)
    }

    func test_key_assign() async {
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false).done { data in
            XCTAssertNotNil(data.address)
            XCTAssertNotEqual(data.address, "")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }
}
