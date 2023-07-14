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
import CommonSources

import CoreMedia
@testable import TorusUtils

class PolygonTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
//        fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .CYAN)
        fnd = NodeDetailManager(network: .legacy(.CYAN))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost, network: .legacy(.CYAN))
        return nodeDetails
    }

    func test_get_public_address() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(val.finalKeyData?.evmAddress, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_getUserTypeAndAddress_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp3 = XCTestExpectation(description: "Should be able to getPublicAddress")
        var verifier: String = "tkey-google-cyan"
        var verifierID: String = TORUS_TEST_EMAIL
        do {
            var nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(data.address, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            exp1.fulfill()

            // exp2
            verifier = "tkey-google-cyan"
            verifierID = "somev2user@gmail.com"
            nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(data.address, "0xdE6805586F158aE3C8B25bBB73eef33ED34883D3")
            exp2.fulfill()

            // exp3
            verifier = "tkey-google-cyan"
            verifierID = "caspertorus@gmail.com"
            nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(data.address, "0xE6bcd804CBFfb95f750e32300517Ad9EC251dAFD")
            exp3.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
            exp2.fulfill()
            exp3.fulfill()
        }
    }

    func test_key_assign_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-cyan"
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

    func test_login_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.privKey, "1e0c955d73e73558f46521da55cc66de7b8fcb56c5b24e851616849b6a1278c8")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_aggregate_login_polygon() async throws {
        let exp1 = XCTestExpectation(description: "should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            XCTAssertEqual(data.ethAddress, "0x34117FDFEFBf1ad2DFA6d4c43804E6C710a6fB04")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}
