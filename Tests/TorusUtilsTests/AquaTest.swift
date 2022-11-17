//
//  PolygonTest.swift
//
//
//  Created by Dhruv Jaiswal on 01/06/22.
//

import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import web3
import XCTest

import CoreMedia
@testable import TorusUtils

class AquaTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: FetchNodeDetails!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
        fnd = FetchNodeDetails(proxyAddress: FetchNodeDetails.proxyAddressAqua, network: .AQUA)
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost, network: .POLYGON)
        return nodeDetails
    }

    func test_get_public_address() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false)
            XCTAssertEqual(val.address, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }

        wait(for: [exp1], timeout: 10)
    }

    func test_getUserTypeAndAddress_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp3 = XCTestExpectation(description: "Should be able to getPublicAddress")
        var verifier: String = "tkey-google-aqua"
        var verifierID: String = TORUS_TEST_EMAIL
        do {
            var nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(data.address, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
            exp2.fulfill()
            exp3.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_key_assign_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false)
            XCTAssertNotNil(data.address)
            XCTAssertNotEqual(data.address, "")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_login_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer)
            XCTAssertEqual(data["privateKey"], "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_aggregate_login_aqua() async throws {
        let exp1 = XCTestExpectation(description: "should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: hashedIDToken, extraParams: buffer)
            XCTAssertEqual(data["publicAddress"], "0x5b58d8a16fDA79172cd42Dc3068d5CEf26a5C81D")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }
}
