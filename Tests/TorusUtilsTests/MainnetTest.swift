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
    
    override func setUpWithError() throws {
        continueAfterFailure = false
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
        
        let exp2 = XCTestExpectation(description: "Should throw if verifier not supported")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER_FAKE, veriferID: TORUS_TEST_EMAIL)
            _ = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER_FAKE, verifierId: TORUS_TEST_EMAIL, isExtended: false)
            XCTFail()
        } catch _ {
            exp2.fulfill()
        }
        
        wait(for: [exp1], timeout: 10)
    }

    func test_shouldLogin() async {
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let data = try await tu.retrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer)
            XCTAssertEqual(data["privateKey"], "0129494416ab5d5f674692b39fa49680e07d3aac01b9683ee7650e40805d4c44")
            exp1.fulfill()
        } catch let error {
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        
        wait(for: [exp1], timeout: 10)
    }
}

