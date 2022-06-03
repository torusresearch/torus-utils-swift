//
//  oneKey.swift
//  
//
//  Created by Dhruv Jaiswal on 02/06/22.
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
import CoreMedia

class OneKeyTest: XCTestCase {

    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd:FetchNodeDetails!
    var tu:TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"
    
    override func setUp() {
        super.setUp()
        fnd = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
    }
    
    func getFNDAndTUData(verifer:String,veriferID:String,enableOneKey:Bool = true) async -> AllNodeDetailsModel{
        return await withCheckedContinuation { continuation in
            _ = fnd.getNodeDetails(verifier: verifer, verifierID: veriferID).done {[unowned self] nodeDetails in
                tu = TorusUtils(nodePubKeys: nodeDetails.getTorusNodePub(), enableOneKey: enableOneKey)
                continuation.resume(returning: nodeDetails)
            }.catch({ error in
                fatalError(error.localizedDescription)
            })
      
        }
    }
    
    func test_fetch_public_address() async{
        let exp1 = XCTestExpectation(description: "should still fetch v1 public address correctly")
        let verifier = "google-lrc"
        let verifierID =  TORUS_TEST_EMAIL
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: true).done { val in
            XCTAssertEqual(val["address"], "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
           // XCTAssertEqual(val["typeOfUser"], TypeOfUser.v1.rawValue)
               exp1.fulfill()
           }.catch { error in
               print(error)
               XCTFail()
               exp1.fulfill()
           }
        wait(for: [exp1], timeout: 10)
        }
    
    
    func test_login() async{
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-cyan"
        let verifierID: String =   TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer).done { data in
               // XCTAssertEqual(data["address"], "0xA3767911A84bE6907f26C572bc89426dDdDB2825".lowercased())
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail(error.localizedDescription)
                exp1.fulfill()
            }
        wait(for: [exp1], timeout: 10)
    }
    
    func test_aggregate_login() async{
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "google-lrc"
        let verifierID: String =   TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let extraParams = ["verifieridentifier": TORUS_TEST_AGGREGATE_VERIFIER, "verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_AGGREGATE_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifierIdentifier: verifier, verifierId: verifierID, idToken: jwt, extraParams: buffer).done { data in
               // XCTAssertEqual(data["address"], "0xA3767911A84bE6907f26C572bc89426dDdDB2825".lowercased())
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail(error.localizedDescription)
                exp1.fulfill()
            }
        wait(for: [exp1], timeout: 10)
    }
    
    func test_key_assign() async{
        let fakeEmail = generateRandomEmail(of: 6)
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        let nodeDetails = await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID, isExtended: false).done { data in
                XCTAssertNotNil(data["address"])
                XCTAssertNotEqual(data["address"],"")
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail(error.localizedDescription)
                exp1.fulfill()
            }
        wait(for: [exp1], timeout: 10)
    }

    

        
    
    
    
    
    
 

}
