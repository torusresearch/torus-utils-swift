import XCTest
import PromiseKit
import FetchNodeDetails
import CryptoSwift
import BigInt
import web3swift
import secp256k1
import CryptorECC

@testable import TorusUtils

func generateRandomEmail(of length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var s = ""
    for _ in 0 ..< length {
        s.append(letters.randomElement()!)
    }
    return s + "@gmail.com"
}

@available(iOS 11.0, *)
final class IntegrationTests: XCTestCase {
    static var fetchNodeDetails: FetchNodeDetails?
    static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: Array<String> = []
    static var nodePubKeys: Array<TorusNodePub> = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "torus-test-health";
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate";
    let TORUS_TEST_EMAIL = "hello@tor.us";
    
    override class func setUp() {
        IntegrationTests.fetchNodeDetails = FetchNodeDetails(proxyAddress: "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183", network: .ROPSTEN)
//        IntegrationTests.nodeDetails = IntegrationTests.fetchNodeDetails?.getNodeDetails()
//        IntegrationTests.endpoints = IntegrationTests.nodeDetails?.getTorusNodeEndpoints() ?? []
//        IntegrationTests.nodePubKeys = IntegrationTests.nodeDetails?.getTorusNodePub() ?? []
            
        IntegrationTests.endpoints = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]
        IntegrationTests.nodePubKeys = [TorusNodePub(_X:  "1363AAD8868CACD7F8946C590325CD463106FB3731F08811AB4302D2DEAE35C3" , _Y:  "D77EEBE5CDF466B475EC892D5B4CFFBE0C1670525DEBBD97EEE6DAE2F87A7CBE" ),
                                        TorusNodePub(_X:  "7C8CC521C48690F016BEA593F67F88AD24F447DD6C31BBAB541E59E207BF029D" , _Y:  "B359F0A82608DB2E06B953B36D0C9A473A00458117CA32A5B0F4563A7D539636" ),
                                        TorusNodePub(_X:  "8A86543CA17DF5687719E2549CAA024CF17FE0361E119E741EAEE668F8DD0A6F" , _Y:  "9CDB254FF915A76950D6D13D78EF054D5D0DC34E2908C00BB009A6E4DA701891" ),
                                        TorusNodePub(_X:  "25A98D9AE006AED1D77E81D58BE8F67193D13D01A9888E2923841894F4B0BF9C" , _Y:  "F63D40DF480DACF68922004ED36DBAB9E2969181B047730A5CE0797FB6958249" ),
                                        TorusNodePub(_X:  "D908F41F8E06324A8A7ABCF702ADB6A273CE3AE63D86A3D22723E1BBF1438C9A" , _Y:  "F977530B3EC0E525438C72D1E768380CBC5FB3B38A760EE925053B2E169428CE" )]
            
        IntegrationTests.utils = TorusUtils(nodePubKeys: IntegrationTests.nodePubKeys, loglevel: .none)
        
//        let fullPath = URL(fileURLWithPath: "/Users/shubham/Documents/github/torus/torus-utils-swift/key.pem" )
//        do{
//            IntegrationTests.privKey = try String(contentsOf: fullPath, encoding: .utf8)
//            let key = try ECPrivateKey(key: IntegrationTests.privKey)
//            print(key.pemString)
//        }catch{
//            print("Unable to read the contents of pem file. Please check the if the file exists \(error)")
//        }
    }
    
    func test_getPublicAddress(){
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        IntegrationTests.utils?.getPublicAddress(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL, isExtended: false).done{ data in
            XCTAssertEqual(data["address"], "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
            exp1.fulfill()
        }.catch{ error in
            print(error)
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 5)
    }
    
    func test_keyAssign(){
        
        let email = generateRandomEmail(of: 6)
        
        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        IntegrationTests.utils?.keyAssign(endpoints: IntegrationTests.endpoints, torusNodePubs: IntegrationTests.nodePubKeys, verifier: "google-lrc", verifierId: email).done{ data in
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
    
    func test_keyLookup(){
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
        
        IntegrationTests.utils?.keyLookup(endpoints: IntegrationTests.endpoints, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL).done{ data in
            XCTAssertEqual(data["address"], "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
            exp1.fulfill()
        }.catch{error in
            XCTFail()
        }
        
        wait(for: [exp1], timeout: 5)

    }
    
    func test_shouldLogin(){
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
    }
    
    var allTests = [
        ("getPublicAddress", test_getPublicAddress),
    ]
}
