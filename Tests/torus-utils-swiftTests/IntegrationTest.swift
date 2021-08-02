import XCTest
import PromiseKit
import FetchNodeDetails
import CryptoSwift
import BigInt
import web3swift
import secp256k1

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
    var fetchNodeDetails: FetchNodeDetails?
    var nodeDetails: NodeDetails?
    var utils: TorusUtils?
    var endpoints: Array<String> = []
    var nodePubKeys: Array<TorusNodePub> = []
    
    let TORUS_TEST_VERIFIER = "torus-test-health";
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate";
    let TORUS_TEST_EMAIL = "hello@tor.us";
    
    override func setUp() {
        self.fetchNodeDetails = FetchNodeDetails(proxyAddress: "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183", network: .ROPSTEN)
        self.nodeDetails = self.fetchNodeDetails?.getNodeDetails()
        self.endpoints = self.nodeDetails?.getTorusNodeEndpoints() ?? []
        self.nodePubKeys = self.nodeDetails?.getTorusNodePub() ?? []
        
        self.utils = TorusUtils(nodePubKeys: self.nodePubKeys)
    }
    
    func test_getPublicAddress(){
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        self.utils?.getPublicAddress(endpoints: self.endpoints, torusNodePubs: self.nodePubKeys, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL, isExtended: false).done{ data in
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
        self.utils?.keyAssign(endpoints: self.endpoints, torusNodePubs: self.nodePubKeys, verifier: "google-lrc", verifierId: email).done{ data in
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
    
    var allTests = [
        ("getPublicAddress", test_getPublicAddress),
    ]
}
