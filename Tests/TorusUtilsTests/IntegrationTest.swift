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
    let TORUS_TEST_VERIFIER_FAKE = "torus-test-ios-fake"
    
    override class func setUp() {
        super.setUp()
        IntegrationTests.fetchNodeDetails = FetchNodeDetails(proxyAddress: "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183", network: .ROPSTEN)
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
    static let nodePubKeys = [TorusNodePubModel(_X:  "1363AAD8868CACD7F8946C590325CD463106FB3731F08811AB4302D2DEAE35C3" , _Y:  "D77EEBE5CDF466B475EC892D5B4CFFBE0C1670525DEBBD97EEE6DAE2F87A7CBE" ),
                              TorusNodePubModel(_X:  "7C8CC521C48690F016BEA593F67F88AD24F447DD6C31BBAB541E59E207BF029D" , _Y:  "B359F0A82608DB2E06B953B36D0C9A473A00458117CA32A5B0F4563A7D539636" ),
                       TorusNodePubModel(_X:  "8A86543CA17DF5687719E2549CAA024CF17FE0361E119E741EAEE668F8DD0A6F" , _Y:  "9CDB254FF915A76950D6D13D78EF054D5D0DC34E2908C00BB009A6E4DA701891" ),
                              TorusNodePubModel(_X:  "25A98D9AE006AED1D77E81D58BE8F67193D13D01A9888E2923841894F4B0BF9C" , _Y:  "F63D40DF480DACF68922004ED36DBAB9E2969181B047730A5CE0797FB6958249" ),
                              TorusNodePubModel(_X:  "D908F41F8E06324A8A7ABCF702ADB6A273CE3AE63D86A3D22723E1BBF1438C9A" , _Y:  "F977530B3EC0E525438C72D1E768380CBC5FB3B38A760EE925053B2E169428CE" )]
}
