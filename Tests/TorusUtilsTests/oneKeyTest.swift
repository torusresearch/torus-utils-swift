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
        fnd = FetchNodeDetails(proxyAddress: FetchNodeDetails.proxyAddressTestnet, network: .TESTNET)
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = true) async throws -> AllNodeDetailsModel {
        do {
            let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
            tu = TorusUtils(enableOneKey: enableOneKey, network: .TESTNET)
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
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: true)
            XCTAssertEqual(data.address, "0xf1e76fcDD28b5AA06De01de508fF21589aB9017E")
            // XCTAssertEqual(val["typeOfUser"], TypeOfUser.v1.rawValue)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer)
            XCTAssertEqual(data.privateKey, "296045a5599afefda7afbdd1bf236358baff580a0fe2db62ae5c1bbe817fbae4")
            exp1.fulfill()
        } catch {
            XCTFail()
            exp1.fulfill()
        }
    }

    func test_login_v2() async {
        let exp1 = XCTestExpectation(description: "should still login v2 account correctly")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = "Jonathan.Nolan@hotmail.com"
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifier_id": verifierID] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer)
            XCTAssertEqual(data.privateKey, "9ec5b0504e252e35218c7ce1e4660eac190a1505abfbec7102946f92ed750075")
            XCTAssertEqual(data.publicAddress, "0x2876820fd9536BD5dd874189A85d71eE8bDf64c2")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_aggregate_login() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: hashedIDToken, extraParams: buffer)
            XCTAssertEqual(data.publicAddress, "0xE1155dB406dAD89DdeE9FB9EfC29C8EedC2A0C8B")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_key_assign() async {
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "google-lrc"
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
    }
    
    func test_v2_key_assign() async {
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: true)
            XCTAssertNotNil(data.address)
            XCTAssertNotEqual(data.address, "")
            XCTAssertEqual(data.typeOfUser, .v2)
            print("data", data.pubNonce)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
    func test_v2_random_login() async {
        let exp1 = XCTestExpectation(description: "should still login v2 account correctly")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = generateRandomEmail(of: 6)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifier_id": verifierID] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer)
            XCTAssertNotNil(data.publicAddress)
            XCTAssertNotNil(data.privateKey)
            XCTAssertNotEqual(data.publicAddress, "")
            XCTAssertNotEqual(data.privateKey, "")
            XCTAssertEqual(data.typeOfUser, .v2)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
    func test_v2_login_web_comptability() async {
        let exp1 = XCTestExpectation(description: "should still login v2 account correctly")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = "iostest@example.com"
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifier_id": verifierID] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer)
            XCTAssertNotNil(data.publicAddress)
            XCTAssertNotNil(data.privateKey)
            XCTAssertNotEqual(data.publicAddress, "")
            XCTAssertNotEqual(data.privateKey, "")
            XCTAssertEqual(data.typeOfUser, .v2)
            print("data.privateKey", data.privateKey, data.publicAddress)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

}
