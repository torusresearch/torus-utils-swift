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

@testable import TorusUtils

@available(iOS 13.0, *)
class MainnetTests: XCTestCase {
    static var fetchNodeDetails: FetchNodeDetails?
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
    var fnd: FetchNodeDetails!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
        fnd = FetchNodeDetails(proxyAddress: FetchNodeDetails.proxyAddressMainnet, network: .MAINNET)
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, network: .MAINNET)
        return nodeDetails
    }

    func test_getPublicAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: "google", veriferID: TORUS_TEST_EMAIL)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: "google", verifierId: TORUS_TEST_EMAIL, isExtended: true)
            XCTAssertEqual(data.address, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
    func test_getUserTypeAndAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier1: String = "tkey-google"
        let verifierID1: String = "somev2user@gmail.com"
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier1, verifierID: verifierID1)

            XCTAssertEqual(val.address, "0xFf669A15bFFcf32D3C5B40bE9E5d409d60D43526")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        
        let exp2 = XCTestExpectation(description: "Should be able to getPublicAddress")
        
        let verifier2: String = "tkey-google"
        let verifierID2: String = "caspertorus@gmail.com"
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier2, verifierID: verifierID2)

            XCTAssertEqual(val.address, "0x61E52B6e488EC3dD6FDc0F5ed04a62Bb9c6BeF53")
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
            let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: email, signerHost: tu.signerHost, network: .TESTNET)
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
        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer)
            XCTAssertEqual(data.privateKey, "0129494416ab5d5f674692b39fa49680e07d3aac01b9683ee7650e40805d4c44")
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
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
            let val = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID, idToken: hashedIDToken, extraParams: buffer)
            XCTAssertEqual(val.publicAddress, "0x621a4d458cFd345dAE831D9E756F10cC40A50381")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
}

