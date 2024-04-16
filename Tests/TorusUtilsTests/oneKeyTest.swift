import BigInt
import CommonSources
import FetchNodeDetails
import JWTKit
import XCTest

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
        fnd = NodeDetailManager(network: .legacy(.TESTNET))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = true) async throws -> AllNodeDetailsModel {
        do {
            let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
            tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.TESTNET), clientId: "YOUR_CLIENT_ID")
            return nodeDetails
        } catch {
            throw error
        }
    }

    func test_fetch_public_address() async throws {
        let verifier = "google-lrc"
        let verifierID = "himanshu@tor.us"
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertEqual(data.finalKeyData?.evmAddress, "0xf1e76fcDD28b5AA06De01de508fF21589aB9017E")
    }

    func test_login() async throws {
        let verifier: String = TORUS_TEST_VERIFIER
        let email = TORUS_TEST_EMAIL
        let verifierID: String = email
        let jwt = try! generateIdToken(email: email)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifier_id": email] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
        XCTAssertEqual(data.finalKeyData?.privKey, "296045a5599afefda7afbdd1bf236358baff580a0fe2db62ae5c1bbe817fbae4")
    }

    func test_login_v2() async throws {
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let extraParams = ["verifier_id": verifierID] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
        XCTAssertEqual(data.oAuthKeyData?.privKey, "068ee4f97468ef1ae95d18554458d372e31968190ae38e377be59d8b3c9f7a25")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0xEfd7eDAebD0D99D1B7C8424b54835457dD005Dc4")
        XCTAssertEqual(data.finalKeyData?.privKey, "296045a5599afefda7afbdd1bf236358baff580a0fe2db62ae5c1bbe817fbae4")
        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x53010055542cCc0f2b6715a5c53838eC4aC96EF7")
    }

    func test_aggregate_login() async throws {
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let hashedIDToken = keccak256Data( jwt.data(using: .utf8) ?? Data() ).toHexString()
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
        XCTAssertEqual(data.finalKeyData?.evmAddress, "0xE1155dB406dAD89DdeE9FB9EfC29C8EedC2A0C8B")
    }

    /* TODO: Investigate this further
    func test_key_assign() async throws {
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertNotNil(data)
        XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
    }
     */
}
