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
        let exp1 = XCTestExpectation(description: "should fetch user type and public address")
        let exp2 = XCTestExpectation(description: "should fetch user type and public address")
        let exp3 = XCTestExpectation(description: "should fetch user type and public address")
        var verifier: String = "tkey-google-cyan"
        var verifierID: String = TORUS_TEST_EMAIL
        do {
            var nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
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

            // exp2
            verifier = "tkey-google-cyan"
            verifierID = "somev2user@gmail.com"
            nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x29446f428293a4E6470AEaEDa6EAfA0F842EF54e")
            XCTAssertEqual(val.oAuthKeyData!.X, "8b6f2048aba8c7833e3b02c5b6522bb18c484ad0025156e428f17fb8d8c34021")
            XCTAssertEqual(val.oAuthKeyData!.Y, "cd9ba153ff89d665f655d1be4c6912f3ff93996e6fe580d89e78bf1476fef2aa")
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0x8EA83Ace86EB414747F2b23f03C38A34E0217814")
            XCTAssertEqual(val.finalKeyData!.X, "cbe7b0f0332e5583c410fcacb6d4ff685bec053cfd943ac75f5e4aa3278a6fbb")
            XCTAssertEqual(val.finalKeyData!.Y, "b525c463f438c7a3c4b018c8c5d16c9ef33b9ac6f319140a22b48b17bdf532dd")
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp2.fulfill()

            // exp3
            verifier = "tkey-google-cyan"
            verifierID = "caspertorus@gmail.com"
            nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID)
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xe8a19482cbe5FaC896A5860Ca4156fb999DDc73b")
            XCTAssertEqual(val.oAuthKeyData!.X, "c491ba39155594896b27cf71a804ccf493289d918f40e6ba4d590f1c76139e9e")
            XCTAssertEqual(val.oAuthKeyData!.Y, "d4649ed9e46461e1af00399a4c65fabb1dc219b3f4af501a7d635c17f57ab553")
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0xCC1f953f6972a9e3d685d260399D6B85E2117561")
            XCTAssertEqual(val.finalKeyData!.X, "8d784434becaad9b23d9293d1f29c4429447315c4cac824cbf2eb21d3f7d79c8")
            XCTAssertEqual(val.finalKeyData!.Y, "fe46a0ef5efe33d16f6cfa678a597be930fbec5432cbb7f3580189c18bd7e157")
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
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
            
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x0b6DB33d8F0A2b47B802845ABc65BB0D9CA287D1")
            XCTAssertEqual(data.finalKeyData?.X, "50867735990590650825986678207784558058703777081079233752705274413018909339153")
            XCTAssertEqual(data.finalKeyData?.Y, "67047321934048669297167101107494432621754670744245489707041940312227332527294")
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
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0xD10F46947f693A6Bf141a014FB98Fd098353Dbd9")
            XCTAssertEqual(data.finalKeyData?.X, "64201800157983909861269393755427755617091903692160691735745245668626073125014")
            XCTAssertEqual(data.finalKeyData?.Y, "97059606175845927312559999719544608745140123184872684648625895866431249911982")
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
