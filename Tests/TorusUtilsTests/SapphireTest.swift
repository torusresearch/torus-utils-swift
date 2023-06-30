//
//  SapphireTest.swift
//  
//
//  Created by CW Lee on 28/06/2023.
//

import XCTest
import CommonSources
import FetchNodeDetails

@testable import TorusUtils
final class SapphireTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    let torusNodeEndpoints = [
        "https://sapphire-dev-2-1.authnetwork.dev/sss/jrpc",
        "https://sapphire-dev-2-2.authnetwork.dev/sss/jrpc",
        "https://sapphire-dev-2-3.authnetwork.dev/sss/jrpc",
        "https://sapphire-dev-2-4.authnetwork.dev/sss/jrpc",
        "https://sapphire-dev-2-5.authnetwork.dev/sss/jrpc"
    ]
    let TORUS_TEST_EMAIL = "saasas@tr.us";
    let TORUS_IMPORT_EMAIL = "importeduser2@tor.us";

    let TORUS_EXTENDED_VERIFIER_EMAIL = "testextenderverifierid@example.com";

    let TORUS_TEST_VERIFIER = "torus-test-health";

    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate";
    let HashEnabledVerifier = "torus-test-verifierid-hash";
    
    var torus: TorusUtils?
    
    override func setUp() {
        super.setUp()
        
        torus = TorusUtils(
            enableOneKey: true,
            allowHost: "https://signer.tor.us/api/allow",
            network: TorusNetwork.SAPPHIRE_DEVNET,
            metadataHost: "https://sapphire-dev-2-1.authnetwork.dev/metadata",
            clientId: "YOUR_CLIENT_ID"
        )
    }
    
    func testFetchPublicAddress() async throws {
        let expectation = self.expectation(description: "Fetching public address")
        let verifierDetails = (verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        
        
        


//        // Wait for the expectation to be fulfilled with a timeout
//        await XCTWaiter().wait(for: [expectation], timeout: 3)

        let nm = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nm.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, isExtended: false)

//        { publicAddress in
//            XCTAssertEqual(publicAddress, "0x4924F91F5d6701dDd41042D94832bB17B76F316F")
//            expectation.fulfill()
//        }
        
//        waitForExpectations(timeout: 10, handler: nil)
    }
}
