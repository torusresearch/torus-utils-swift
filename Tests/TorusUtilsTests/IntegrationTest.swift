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

@available(iOS 11.0, *)
final class IntegrationTests: XCTestCase {
    static var fetchNodeDetails: FetchNodeDetails?
    // static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: Array<String> = []
    static var nodePubKeys: Array<TorusNodePubModel> = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "tkey-google-lrc"
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-ios-public-agg"
    let TORUS_TEST_AGGREGATE_VERIFIER_SUB1 = "torus-test-ios-public-agg1"
    let TORUS_TEST_AGGREGATE_VERIFIER_SUB2 = "torus-test-ios-public-agg2"
    let TORUS_TEST_EMAIL = "hello@tor.us"

    // Fake data
    let TORUS_TEST_VERIFIER_FAKE = "google-lrc"

    override class func setUp() {
        super.setUp()
        IntegrationTests.fetchNodeDetails = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
        // IntegrationTests.nodeDetails = IntegrationTests.fetchNodeDetails?.getNodeDetails()
        // IntegrationTests.endpoints = IntegrationTests.nodeDetails?.getTorusNodeEndpoints() ?? []
        // IntegrationTests.nodePubKeys = IntegrationTests.nodeDetails?.getTorusNodePub() ?? []

        // Faster logins by mocking data.
        IntegrationTests.endpoints = ROPSTEN_CONSTANTS.endpoints
        IntegrationTests.nodePubKeys = ROPSTEN_CONSTANTS.nodePubKeys

        IntegrationTests.utils = TorusUtils(nodePubKeys: IntegrationTests.nodePubKeys, enableOneKey: false)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_secpTest(){
        if let key = Data(hex: "fda99cc749072df6aae7b2866017bcf4d371bb12949317d37bd1d2d5eb4dcf7f"){
            let publicKey = SECP256K1.privateToPublic(privateKey: key)?.subdata(in: 1 ..< 65);
            let address1 = IntegrationTests.utils?.publicKeyToAddress(key: publicKey!).toHexString();
            
            let address2 = IntegrationTests.utils?.publicKeyToAddress(key: publicKey!.toHexString());
            XCTAssertEqual(address1, address2)
        }
    }
    
    
    

    func test_getPublicAddress() {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fnd = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
       _ =  fnd.getNodeDetails(verifier: "tkey-google-lrc", verifierID: "somev2user@gmail.com").done { nodeDetails in
           IntegrationTests.utils?.getPublicAddress(endpoints:nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: "tkey-google-lrc", verifierId: "somev2user@gmail.com", isExtended: true).done { data in
               print(data)
               XCTAssertEqual(data["address"], "0x376597141d8d219553378313d18590F373B09795")
               exp1.fulfill()
           }.catch { error in
               print(error)
               XCTFail()
           }
        }
      
        wait(for: [exp1], timeout: 10)
        
        
        

//        let exp2 = XCTestExpectation(description: "Should throw if verifier not supported")
//        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: TORUS_TEST_VERIFIER_FAKE, verifierId: TORUS_TEST_EMAIL, isExtended: false).done { _ in
//            XCTFail()
//        }.catch { error in
//            XCTAssertEqual(error as! String, "getPublicAddress: err: Verifier not supported")
//            exp2.fulfill()
//        }
   
    }
    
    
    func test_getUserTypeAndAddress() {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier:String = "tkey-google-lrc"
        let verifierID:String = "caspertorus@gmail.com"
        let fnd = FetchNodeDetails(proxyAddress: "0x6258c9d6c12ed3edda59a1a6527e469517744aa7", network: .ROPSTEN)
       _ =  fnd.getNodeDetails(verifier: verifier, verifierID: verifierID).done { nodeDetails in
           IntegrationTests.utils?.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePub: nodeDetails.getTorusNodePub(), verifier: verifier, verifierID: verifierID).done { address in
               XCTAssertEqual(address, "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
               exp1.fulfill()
           }.catch { error in
               print(error)
               XCTFail()
           }
               
           }
      
        wait(for: [exp1], timeout: 10)
    }
    
    func test_polygon_public_address(){
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let fnd = FetchNodeDetails(proxyAddress: "0x9f072ba19b3370e512aa1b4bfcdaf97283168005", network: .POLYGON)
        _ = fnd.getNodeDetails(verifier: "tkey-google-cyan", verifierID: "somev2user@gmail.com").done { nodeDetails in
            IntegrationTests.utils?.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: "tkey-google-cyan", verifierId: "somev2user@gmail.com", isExtended: false).done { data in
                XCTAssertEqual(data["address"], "0x8EA83Ace86EB414747F2b23f03C38A34E0217814")
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail()
            }
        }
        wait(for: [exp1], timeout: 10)
    }

    func test_keyAssign() {
        let email = generateRandomEmail(of: 6)

        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        IntegrationTests.utils?.keyAssign(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: TORUS_TEST_VERIFIER, verifierId: email).done { data in
            let result = data.result as! [String: Any]
            let keys = result["keys"] as! [[String: String]]
            let address = keys[0]["address"]

            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        }.catch { _ in
            XCTFail()
        }

        wait(for: [exp1], timeout: 15)
    }

    func test_keyLookup() {
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL).done { data in
            XCTAssertEqual(data["address"], "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
            exp1.fulfill()
        }.catch { _ in
            XCTFail()
        }

        let exp2 = XCTestExpectation(description: "Should not be able to do keylookup")
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: "google-lrc-fake", verifierId: TORUS_TEST_EMAIL).done { data in
            XCTAssertEqual(data["err"]!, "Verifier not supported")
            exp2.fulfill()
        }.catch { _ in
            XCTFail()
        }

        wait(for: [exp1, exp2], timeout: 10)
    }

    func test_shouldLogin() {
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")

        do {
            let jwt = try generateIdToken(email: TORUS_TEST_EMAIL)
            let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)

            IntegrationTests.utils?.retrieveShares(endpoints: IntegrationTests.endpoints, verifierIdentifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer).done { data in
                XCTAssertEqual(data["publicAddress"], "0xF2c682Fc2e053D03Bb91846d6755C3A31ed34C0f")
                exp1.fulfill()
            }.catch { error in
                print(error)
                XCTFail()
            }
        } catch {
            XCTFail("\(error)")
        }

        wait(for: [exp1], timeout: 10)
    }

    // MARK: Aggregate tests

    func test_getPublicAddressAggregateLogin() {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL, isExtended: false).done { data in
            XCTAssertEqual(data["address"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
            exp1.fulfill()
        }.catch { error in
            print(error)
            XCTFail()
        }

        wait(for: [exp1], timeout: 5)
    }

    func test_keyAssignAggregateLogin() {
        let email = generateRandomEmail(of: 6)

        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        IntegrationTests.utils?.keyAssign(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: email).done { data in
            let result = data.result as! [String: Any]
            let keys = result["keys"] as! [[String: String]]
            let address = keys[0]["address"]

            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        }.catch { _ in
            XCTFail()
        }

        wait(for: [exp1], timeout: 5)
    }

    func test_keyLookupAggregateLogin() {
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookupAggregateLogin")

        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL).done { data in
            XCTAssertEqual(data["address"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
            exp1.fulfill()
        }.catch { _ in
            XCTFail()
        }

        wait(for: [exp1], timeout: 5)
    }

    func test_shouldAggregateLogin() {
        let exp1 = XCTestExpectation(description: "Should be able to do a aggregate login")
        do {
            let jwt = try generateIdToken(email: TORUS_TEST_EMAIL)
            let extraParams = ["verifieridentifier": TORUS_TEST_AGGREGATE_VERIFIER, "verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_AGGREGATE_VERIFIER_SUB1], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Any]
            let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)

            IntegrationTests.utils?.retrieveShares(endpoints: IntegrationTests.endpoints, verifierIdentifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL, idToken: jwt.sha3(.keccak256), extraParams: buffer).done { data in
                XCTAssertEqual(data["publicAddress"], "0xF9f6742d29B4524a3e56f2d7EBE718a31E73CAD1")
                exp1.fulfill()
            }.catch { _ in
                XCTFail()
            }
        } catch {
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
