//
//  oneKey.swift
//
//
//  Created by Dhruv Jaiswal on 02/06/22.
//

import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import web3
import XCTest
import CommonSources

import CoreMedia
@testable import TorusUtils

class OneKeyTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
//        fnd = FetchNodeDetails(proxyAddress: FetchNodeDetails.proxyAddressTestnet, network: .TESTNET)
        fnd = NodeDetailManager(network: .legacy(.TESTNET))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = true) async throws -> AllNodeDetailsModel {
        do {
            let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
            tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.TESTNET))
            return nodeDetails
        } catch {
            throw error
        }
    }

    func test_fetch_public_address() async {
        let exp1 = XCTestExpectation(description: "should still fetch v1 public address correctly")
        let verifier = "google-lrc"
        let verifierID = "himanshu@tor.us"
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0xf1e76fcDD28b5AA06De01de508fF21589aB9017E")
            // XCTAssertEqual(val["typeOfUser"], TypeOfUser.v1.rawValue)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login() async {
        let exp1 = XCTestExpectation(description: "should still login v1 account correctly")
        let verifier: String = TORUS_TEST_VERIFIER
        let email = TORUS_TEST_EMAIL
        let verifierID: String = email
        let jwt = try! generateIdToken(email: email)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifier_id": email] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(),  verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.finalKeyData?.privKey, "296045a5599afefda7afbdd1bf236358baff580a0fe2db62ae5c1bbe817fbae4")
            exp1.fulfill()
        } catch let err{
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login_v2() async {
        let exp1 = XCTestExpectation(description: "should still login v2 account correctly")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifier_id": verifierID] as [String: Codable]
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(),  verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.finalKeyData?.privKey, "296045a5599afefda7afbdd1bf236358baff580a0fe2db62ae5c1bbe817fbae4")
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x53010055542cCc0f2b6715a5c53838eC4aC96EF7")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_aggregate_login() async {
        let exp1 = XCTestExpectation(description: "Should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(),  verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0xE1155dB406dAD89DdeE9FB9EfC29C8EedC2A0C8B")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_key_assign() async {
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to assign key")
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertNotNil(data)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}
