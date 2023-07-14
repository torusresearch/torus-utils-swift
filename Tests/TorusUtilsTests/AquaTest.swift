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

class AquaTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager( network: .legacy(.AQUA))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost, network: .legacy(.AQUA))
        return nodeDetails
    }

    func test_get_public_address() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let val = try await tu.getPublicAddressExtended(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
            XCTAssertEqual(val.finalKeyData!.X, "4fc8db5d3fe164a3ab70fd6348721f2be848df2cc02fd2db316a154855a7aa7d")
            XCTAssertEqual(val.finalKeyData!.Y, "f76933cbf5fe2916681075bb6cb4cde7d5f6b6ce290071b1b7106747d906457c")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
            XCTAssertEqual(val.oAuthKeyData!.X, "4fc8db5d3fe164a3ab70fd6348721f2be848df2cc02fd2db316a154855a7aa7d")
            XCTAssertEqual(val.oAuthKeyData!.Y, "f76933cbf5fe2916681075bb6cb4cde7d5f6b6ce290071b1b7106747d906457c")
            XCTAssertNil(val.metadata?.pubNonce)
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_getUserTypeAndAddress_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let exp3 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(data.address, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
            exp2.fulfill()
            exp3.fulfill()
        }
    }

    func test_key_assign_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddressExtended(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertNotNil(data.finalKeyData)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login_aqua() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares( endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_aggregate_login_aqua() async throws {
        let exp1 = XCTestExpectation(description: "should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            XCTAssertEqual(data.ethAddress, "0x5b58d8a16fDA79172cd42Dc3068d5CEf26a5C81D")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}

extension AquaTest {
    func test_retrieveShares_some_nodes_down() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var endpoints = nodeDetails.getTorusNodeEndpoints()
            endpoints[0] =    "https://ndjnfjbfrj/random"
            // should fail if un-commented threshold 4/5
            // endpoints[1] = "https://ndjnfjbfrj/random"
            let data = try await tu.retrieveShares(endpoints: endpoints, torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}
