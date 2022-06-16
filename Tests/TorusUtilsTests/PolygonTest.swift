//
//  PolygonTest.swift
//
//
//  Created by Dhruv Jaiswal on 01/06/22.
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

class PolygonTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: FetchNodeDetails!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
        fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .POLYGON)
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async -> AllNodeDetailsModel {
        return await withCheckedContinuation { continuation in
            _ = fnd.getNodeDetails(verifier: verifer, verifierID: veriferID).done { [unowned self] nodeDetails in
                tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost)
                continuation.resume(returning: nodeDetails)
            }.catch({ error in
                fatalError(error.localizedDescription)
            })
        }
    }

    func test_get_public_address() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = TORUS_TEST_EMAIL
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { val in
            XCTAssertEqual(val.address, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
        }

        wait(for: [exp1], timeout: 10)
    }

    func test_getUserTypeAndAddress_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        var verifier: String = "tkey-google-cyan"
        var verifierID: String = TORUS_TEST_EMAIL
        var nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { val in
            XCTAssertEqual(val.address, "0xA3767911A84bE6907f26C572bc89426dDdDB2825")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
            exp1.fulfill()
        }

        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
        verifier = "tkey-google-cyan"
        verifierID = "somev2user@gmail.com"
        nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { val in
            XCTAssertEqual(val.address, "0xdE6805586F158aE3C8B25bBB73eef33ED34883D3")
            exp2.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
            exp2.fulfill()
        }

        let exp3 = XCTestExpectation(description: "Should be able to getPublicAddress")
        verifier = "tkey-google-cyan"
        verifierID = "caspertorus@gmail.com"
        nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { val in
            XCTAssertEqual(val.address, "0xE6bcd804CBFfb95f750e32300517Ad9EC251dAFD")
            exp3.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
            exp3.fulfill()
        }

        wait(for: [exp1, exp2, exp3], timeout: 10)
    }

    func test_key_assign_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = fakeEmail
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false).done { data in
            XCTAssertNotNil(data.address)
            XCTAssertNotEqual(data.address, "")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_login_polygon() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer).done { data in
            XCTAssertEqual(data["privateKey"], "1e0c955d73e73558f46521da55cc66de7b8fcb56c5b24e851616849b6a1278c8")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_aggregate_login_polygon() async {
        let exp1 = XCTestExpectation(description: "should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: hashedIDToken, extraParams: buffer).done { data in
            XCTAssertEqual(data["publicAddress"], "0x34117FDFEFBf1ad2DFA6d4c43804E6C710a6fB04")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }
}
