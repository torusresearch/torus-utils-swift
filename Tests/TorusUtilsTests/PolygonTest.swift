//
//  PolygonTest.swift
//  
//
//  Created by Dhruv Jaiswal on 01/06/22.
//

import XCTest
import BigInt
import CryptorECC
import CryptoSwift
import FetchNodeDetails
import JWTKit
import PromiseKit
import secp256k1
import web3
import XCTest

@testable import TorusUtils

class PolygonTest: XCTestCase {
    
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"

    func test_getUserTypeAndAddress_polygon() {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = "somev2user@gmail.com"
        let fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .POLYGON)
        _ = fnd.getNodeDetails(verifier: verifier, verifierID: "hello@tor.us").done { nodeDetails in
         let tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), signerHost: "https://signer-polygon.tor.us/api/sign", allowHost: "https://signer-polygon.tor.us/api/allow")
         tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { address in
             XCTAssertEqual(address, "0x8EA83Ace86EB414747F2b23f03C38A34E0217814".lowercased())
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail()
            }
        }

        wait(for: [exp1], timeout: 10)
    }
    
 
    func test_key_assign_polygon() {
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String = fakeEmail
        let fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .POLYGON)
        _ = fnd.getNodeDetails(verifier: verifier, verifierID: verifierID).done { nodeDetails in
         let tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), signerHost: "https://signer-polygon.tor.us/api/sign", allowHost: "https://signer-polygon.tor.us/api/allow")
            tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false).done { data in
                XCTAssertNotEqual(data["address"],"")
                XCTAssertNotNil(data["address"])
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail()
            }
        }

        wait(for: [exp1], timeout: 10)
    }
    
    
    func test_shouldLogin_polygon() {
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
        do {
            let jwt = try generateIdToken(email: TORUS_TEST_EMAIL)
            let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
            let fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .POLYGON)
            fnd.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL).done{ nodeDetails in
                let tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), signerHost: "https://signer-polygon.tor.us/api/sign", allowHost: "https://signer-polygon.tor.us/api/allow")
                tu.retrieveShares(endpoints: endpoints, verifierIdentifier: self.TORUS_TEST_VERIFIER, verifierId: self.TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer).done { data in
                XCTAssertEqual(data["publicAddress"], "1e0c955d73e73558f46521da55cc66de7b8fcb56c5b24e851616849b6a1278c8")
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail()
            }
        }.catch { error in
            XCTFail(error.localizedDescription)
            }
        }
        catch{
            XCTFail()
        }

        wait(for: [exp1], timeout: 10)
    }
    
    

}
