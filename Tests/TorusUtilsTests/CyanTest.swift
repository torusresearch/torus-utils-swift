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

class CyanTest: XCTestCase {
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
        let exp1 = XCTestExpectation(description: "should fetch public address")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            XCTAssertEqual(val.finalKeyData!.X, "2853f323437da98ce021d06854f4b292db433c0ad03b204ef223ac2583609a6a")
            XCTAssertEqual(val.finalKeyData!.Y, "f026b4788e23523e0c8fcbf0bdcf1c1a62c9cde8f56170309607a7a52a19f7c1")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            XCTAssertEqual(val.oAuthKeyData!.X, "2853f323437da98ce021d06854f4b292db433c0ad03b204ef223ac2583609a6a")
            XCTAssertEqual(val.oAuthKeyData!.Y, "f026b4788e23523e0c8fcbf0bdcf1c1a62c9cde8f56170309607a7a52a19f7c1")
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

    func test_getUserTypeAndAddress_polygon() async {
            let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
            let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
            let exp3 = XCTestExpectation(description: "Should be able to getPublicAddress")
            var verifier: String = "tkey-google-cyan"
            var verifierID: String = TORUS_TEST_EMAIL
            do {
                var nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
                var data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
                XCTAssertEqual(data.finalKeyData?.evmAddress, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
                exp1.fulfill()

                // exp2
                verifier = "tkey-google-cyan"
                verifierID = "somev2user@gmail.com"
                nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
                data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
                XCTAssertEqual(data.finalKeyData?.evmAddress, "0xdE6805586F158aE3C8B25bBB73eef33ED34883D3")
                exp2.fulfill()

                // exp3
                verifier = "tkey-google-cyan"
                verifierID = "caspertorus@gmail.com"
                nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
                data = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
                XCTAssertEqual(data.finalKeyData?.evmAddress, "0xE6bcd804CBFfb95f750e32300517Ad9EC251dAFD")
                exp3.fulfill()
            } catch let err {
                XCTFail(err.localizedDescription)
                exp1.fulfill()
                exp2.fulfill()
                exp3.fulfill()
            }
        }

    func test_key_assign_polygon() async {
        let exp1 = XCTestExpectation(description: "should be able to key assign")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertNotNil(data)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to login")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x8AA6C8ddCD868873120aA265Fc63E3a2180375BA")
            XCTAssertEqual(data.finalKeyData?.X, "35739417e3be1b1e56cdf8c509d8dee5412712514b18df1bc961ac6465a0c949")
            XCTAssertEqual(data.finalKeyData?.Y, "887497602e62ced686eb99eaa0020b0c0d705cad96eafeec2dd1bbfb6a9d42c2")
            XCTAssertEqual(data.finalKeyData?.privKey, "1e0c955d73e73558f46521da55cc66de7b8fcb56c5b24e851616849b6a1278c8")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x8AA6C8ddCD868873120aA265Fc63E3a2180375BA")
            XCTAssertEqual(data.oAuthKeyData?.X, "35739417e3be1b1e56cdf8c509d8dee5412712514b18df1bc961ac6465a0c949")
            XCTAssertEqual(data.oAuthKeyData?.Y, "887497602e62ced686eb99eaa0020b0c0d705cad96eafeec2dd1bbfb6a9d42c2")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "1e0c955d73e73558f46521da55cc66de7b8fcb56c5b24e851616849b6a1278c8")
            XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce, nil)
            XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            XCTAssertEqual(data.metadata?.upgraded, nil)
            XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
            
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
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x34117FDFEFBf1ad2DFA6d4c43804E6C710a6fB04")
            XCTAssertEqual(data.finalKeyData?.X, "afd12f2476006ef6aa8778190b29676a70039df8688f9dee69c779bdc8ff0223")
            XCTAssertEqual(data.finalKeyData?.Y, "e557a5ee879632727f5979d6b9cea69d87e3dab54a8c1b6685d86dfbfcd785dd")
            XCTAssertEqual(data.finalKeyData?.privKey, "45a5b62c4ff5490baa75d33bf4f03ba6c5b0095678b0f4055312eef7b780b7bf")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x34117FDFEFBf1ad2DFA6d4c43804E6C710a6fB04")
            XCTAssertEqual(data.oAuthKeyData?.X, "afd12f2476006ef6aa8778190b29676a70039df8688f9dee69c779bdc8ff0223")
            XCTAssertEqual(data.oAuthKeyData?.Y, "e557a5ee879632727f5979d6b9cea69d87e3dab54a8c1b6685d86dfbfcd785dd")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "45a5b62c4ff5490baa75d33bf4f03ba6c5b0095678b0f4055312eef7b780b7bf")
            XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce, nil)
            XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            XCTAssertEqual(data.metadata?.upgraded, nil)
            XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}
