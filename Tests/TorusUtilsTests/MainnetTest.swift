//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 31/03/23.
//

import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import web3
import XCTest

import CommonSources

@testable import TorusUtils

@available(iOS 13.0, *)
class MainnetTests: XCTestCase {
    static var fetchNodeDetails: AllNodeDetailsModel?
    // static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: [String] = []
    static var nodePubKeys: [TorusNodePubModel] = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "torus-test-health"
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    let TORUS_TEST_EMAIL = "hello@tor.us"
    var signerHost = "https://signer.tor.us/api/sign"
    var allowHost = "https://signer.tor.us/api/allow"

    // Fake data
    let TORUS_TEST_VERIFIER_FAKE = "google-lrc-fakes"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager(network: .legacy(.MAINNET))
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.MAINNET))
        return nodeDetails
    }

    func test_getPublicAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: "google", veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getPublicAddressExtended(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub , verifier: "google", verifierId: TORUS_TEST_EMAIL )
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
            XCTAssertEqual(val.finalKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
            XCTAssertEqual(val.finalKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
            XCTAssertEqual(val.oAuthKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
            XCTAssertEqual(val.oAuthKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
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

    func test_getUserTypeAndAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier1: String = "google"
        let verifierID1: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier1, verifierID: verifierID1)

            XCTAssertEqual(val.finalKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
            XCTAssertEqual(val.finalKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
            XCTAssertEqual(val.finalKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
            XCTAssertEqual(val.oAuthKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
            XCTAssertEqual(val.oAuthKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
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

        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")

        let verifier2: String = "tkey-google"
        let verifierID2: String = "somev2user@gmail.com"
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier2, veriferID: verifierID2)
            let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier2, verifierID: verifierID2)

            XCTAssertEqual(val.finalKeyData!.evmAddress, "0xFf669A15bFFcf32D3C5B40bE9E5d409d60D43526")
            XCTAssertEqual(val.finalKeyData!.X, "bbfd26b1e61572c4e991a21b64f12b313cb6fce6b443be92d4d5fd8f311e8f33")
            XCTAssertEqual(val.finalKeyData!.Y, "df2c905356ec94faaa111a886be56ed6fa215b7facc1d1598486558355123c25")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xA9c6829e4899b6D630130ebf59D046CA868D7f83")
            XCTAssertEqual(val.oAuthKeyData!.X, "5566cd940ea540ba1a3ba2ff0f5fd3d9a3a74350ac3baf47b811592ae6ea1c30")
            XCTAssertEqual(val.oAuthKeyData!.Y, "07a302e87e8d9eb5d143f570c248657288c13c09ecbe1e3a8720449daf9315b0")
            XCTAssertEqual(val.metadata?.pubNonce?.x, "96f4b7d3c8c8c69cabdea46ae1eedda346b03cad8ba1a454871b0ec6a69861f3")
            XCTAssertEqual(val.metadata?.pubNonce?.y, "da3aed7f7e9d612052beb1d92ec68a8dcf60faf356985435b424af2423f66672")
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp2.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp2.fulfill()
        }
    }

    func test_keyAssign() async {
        let email = generateRandomEmail(of: 6)

        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: "google", veriferID: email)
            let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: email, signerHost: tu.signerHost, network: .legacy(.TESTNET))
            let result = val.result as! [String: Any]
            let keys = result["keys"] as! [[String: String]]
            let address = keys[0]["address"]

            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_shouldLogin() async {
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Codable]
//        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
           
            XCTAssertEqual(data.finalKeyData?.privKey, "0129494416ab5d5f674692b39fa49680e07d3aac01b9683ee7650e40805d4c44")
            exp1.fulfill()
        } catch let error {
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_shouldAggregateLogin() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
            
            let val = try await tu.retrieveShares(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub, verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            
            XCTAssertEqual(val.oAuthKeyData?.evmAddress, "0x621a4d458cFd345dAE831D9E756F10cC40A50381")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

}
