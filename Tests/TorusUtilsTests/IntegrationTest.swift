import XCTest
import PromiseKit
import FetchNodeDetails
import CryptoSwift
import BigInt
import web3
import secp256k1
import CryptorECC
import JWTKit

@testable import TorusUtils

@available(iOS 11.0, *)
final class IntegrationTests: XCTestCase {
    static var fetchNodeDetails: FetchNodeDetails?
   // static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: Array<String> = []
    static var nodePubKeys: Array<TorusNodePubModel> = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "torus-test-ios-public";
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-ios-public-agg";
    let TORUS_TEST_AGGREGATE_VERIFIER_SUB1 = "torus-test-ios-public-agg1"
    let TORUS_TEST_AGGREGATE_VERIFIER_SUB2 = "torus-test-ios-public-agg2"
    let TORUS_TEST_EMAIL = "hello@tor.us";
    
    // Fake data
    let TORUS_TEST_VERIFIER_FAKE = "torus-test-ios"
    
    override class func setUp() {
        super.setUp()
        IntegrationTests.fetchNodeDetails = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
        // IntegrationTests.nodeDetails = IntegrationTests.fetchNodeDetails?.getNodeDetails()
        // IntegrationTests.endpoints = IntegrationTests.nodeDetails?.getTorusNodeEndpoints() ?? []
        // IntegrationTests.nodePubKeys = IntegrationTests.nodeDetails?.getTorusNodePub() ?? []
            
        // Faster logins by mocking data.
        IntegrationTests.endpoints = ROPSTEN_CONSTANTS.endpoints
        IntegrationTests.nodePubKeys = ROPSTEN_CONSTANTS.nodePubKeys
            
        IntegrationTests.utils = TorusUtils(nodePubKeys: IntegrationTests.nodePubKeys)
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_getPublicAddress(){
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: self.TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, isExtended: false).done{ data in
            XCTAssertEqual(data["address"], "0xF2c682Fc2e053D03Bb91846d6755C3A31ed34C0f")
            exp1.fulfill()
        }.catch{ error in
            print(error)
            XCTFail()
        }
        
        let exp2 = XCTestExpectation(description: "Should throw if verifier not supported")
        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: self.TORUS_TEST_VERIFIER_FAKE, verifierId: TORUS_TEST_EMAIL, isExtended: false).done{ data in
            XCTFail()
        }.catch{ error in
            XCTAssertEqual(error as! String, "getPublicAddress: err: Verifier not supported")
            exp2.fulfill()
        }
        wait(for: [exp1, exp2], timeout: 10)
    }
    
    func test_keyAssign(){
        
        let email = generateRandomEmail(of: 6)
        
        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        IntegrationTests.utils?.keyAssign(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: self.TORUS_TEST_VERIFIER, verifierId: email).done{ data in
            let result = data.result as! [String:Any]
            let keys = result["keys"] as! [[String:String]]
            let address = keys[0]["address"]
            
            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 15)
    }
    
    func test_keyLookup(){
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL).done{ data in
            XCTAssertEqual(data["address"], "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
            exp1.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        let exp2 = XCTestExpectation(description: "Should not be able to do keylookup")
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: "google-lrc-fake", verifierId: TORUS_TEST_EMAIL).done{ data in
            XCTAssertEqual(data["err"]!, "Verifier not supported")
            exp2.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        wait(for: [exp1, exp2], timeout: 10)
    }
    
    func test_shouldLogin(){
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
        
        do{
            let jwt = try generateIdToken(email: self.TORUS_TEST_EMAIL)
            let extraParams = ["verifieridentifier": self.TORUS_TEST_VERIFIER, "verifier_id": self.TORUS_TEST_EMAIL] as [String : Any]
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
            
            IntegrationTests.utils?.retrieveShares(endpoints: IntegrationTests.endpoints, verifierIdentifier: self.TORUS_TEST_VERIFIER, verifierId: self.TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer).done{ data in
                XCTAssertEqual(data["publicAddress"], "0xF2c682Fc2e053D03Bb91846d6755C3A31ed34C0f")
                exp1.fulfill()
            }.catch{ error in
                print(error)
                XCTFail()
            }
        }catch{
            XCTFail("\(error)")
        }
        
        wait(for: [exp1], timeout: 10)
    }
    
    // MARK: Aggregate tests
    
    func test_getPublicAddressAggregateLogin(){
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL, isExtended: false).done{ data in
            XCTAssertEqual(data["address"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
            exp1.fulfill()
        }.catch{ error in
            print(error)
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 5)
    }
    
    
    func test_keyAssignAggregateLogin(){
        
        let email = generateRandomEmail(of: 6)
        
        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        IntegrationTests.utils?.keyAssign(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: self.TORUS_TEST_AGGREGATE_VERIFIER, verifierId: email).done{ data in
            let result = data.result as! [String:Any]
            let keys = result["keys"] as! [[String:String]]
            let address = keys[0]["address"]
            
            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 5)
        
    }
    
    func test_keyLookupAggregateLogin(){
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookupAggregateLogin")
        
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: self.TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL).done{ data in
            XCTAssertEqual(data["address"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
            exp1.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 5)

    }
    
    func test_shouldAggregateLogin(){
        let exp1 = XCTestExpectation(description: "Should be able to do a aggregate login")
        do{
            let jwt = try generateIdToken(email: self.TORUS_TEST_EMAIL)
            let extraParams = ["verifieridentifier": self.TORUS_TEST_AGGREGATE_VERIFIER, "verifier_id": self.TORUS_TEST_EMAIL, "sub_verifier_ids":[self.TORUS_TEST_AGGREGATE_VERIFIER_SUB1], "verify_params": [["verifier_id": self.TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String : Any]
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
            
            IntegrationTests.utils?.retrieveShares(endpoints: IntegrationTests.endpoints, verifierIdentifier: self.TORUS_TEST_AGGREGATE_VERIFIER, verifierId: self.TORUS_TEST_EMAIL, idToken: jwt.sha3(.keccak256), extraParams: buffer).done{ data in
                XCTAssertEqual(data["publicAddress"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
                exp1.fulfill()
            }.catch{ error in
                XCTFail()
            }
        }catch{
            XCTFail("\(error)")
        }
        
        wait(for: [exp1], timeout: 10)
    }
    
    var allTests = [
        ("getPublicAddress", test_getPublicAddress),
    ]
}

struct ROPSTEN_CONSTANTS {
    static let endpoints = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]
    static let nodePubKeys = [TorusNodePubModel(_X: "1363aad8868cacd7f8946c590325cd463106fb3731f08811ab4302d2deae35c3", _Y: "d77eebe5cdf466b475ec892d5b4cffbe0c1670525debbd97eee6dae2f87a7cbe"), TorusNodePubModel(_X: "7c8cc521c48690f016bea593f67f88ad24f447dd6c31bbab541e59e207bf029d", _Y: "b359f0a82608db2e06b953b36d0c9a473a00458117ca32a5b0f4563a7d539636"), TorusNodePubModel(_X: "8a86543ca17df5687719e2549caa024cf17fe0361e119e741eaee668f8dd0a6f", _Y: "9cdb254ff915a76950d6d13d78ef054d5d0dc34e2908c00bb009a6e4da701891"), TorusNodePubModel(_X: "25a98d9ae006aed1d77e81d58be8f67193d13d01a9888e2923841894f4b0bf9c", _Y: "f63d40df480dacf68922004ed36dbab9e2969181b047730a5ce0797fb6958249"), TorusNodePubModel(_X: "d908f41f8e06324a8a7abcf702adb6a273ce3ae63d86a3d22723e1bbf1438c9a", _Y: "f977530b3ec0e525438c72d1e768380cbc5fb3b38a760ee925053b2e169428ce")]
}
