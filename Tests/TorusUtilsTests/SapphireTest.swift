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
        let verifierDetails = (verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let publicAddress = try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(publicAddress?.lowercased(), "0x4924F91F5d6701dDd41042D94832bB17B76F316F".lowercased())
        print("pass check")
    }
    
    func testKeepPublicAddressSame() async throws {
        let verifierDetails = (verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        // fixme
        let verifierId = TORUS_TEST_EMAIL //faker random address
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: verifierId)
        let publicAddress = try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: verifierId)
        let publicAddress2 = try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: verifierId)

        XCTAssertEqual(publicAddress, publicAddress2)
        XCTAssertNotEqual(publicAddress, nil)
        XCTAssertNotEqual(publicAddress, "")
    }
    
    func testFetchPublicAddressAndUserType() async throws {
        let verifierDetails = (verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        print (endpoint.torusNodeSSSEndpoints)
        let result = try await torus?.getPublicAddressExtended(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

        XCTAssertEqual(result?.address.lowercased(), "0x4924F91F5d6701dDd41042D94832bB17B76F316F".lowercased())
    }

//    it("should be able to key assign", async function () {
//      const email = faker.internet.email();
//      const verifierDetails = { verifier: TORUS_TEST_VERIFIER, verifierId: email };
//      const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails(verifierDetails);
//      const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//      const publicAddress = await torus.getPublicAddress(torusNodeEndpoints, verifierDetails);
//      expect(publicAddress).to.not.equal("");
//      expect(publicAddress).to.not.equal(null);
//    });
    
    func testAbleToLogin() async throws {
        let token = try generateIdToken(email: TORUS_TEST_EMAIL)
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoints = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let response = try await torus?.retrieveShares(endpoints: endpoints.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)
        print(response)
        
        XCTAssertEqual(response?.privKey.lowercased(), "04eb166ddcf59275a210c7289dca4a026f87a33fd2d6ed22f56efae7eab4052c".lowercased())
    }
    
    func testNodeDownAbleToLogin () async throws {
        let token = try generateIdToken(email: TORUS_TEST_EMAIL)
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoints = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        var sssEndpoints = endpoints.torusNodeSSSEndpoints
        sssEndpoints[1] = "https://example.com"
        let response = try await torus?.retrieveShares(endpoints: endpoints.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)
        print(response)
        XCTAssertEqual(response?.privKey.lowercased(), "04eb166ddcf59275a210c7289dca4a026f87a33fd2d6ed22f56efae7eab4052c".lowercased())
    }

//    func teststring() {
//        let metadata = EciesHex(iv: <#T##String#>, ephemPublicKey: <#T##String#>, ciphertext: <#T##String#>, mac: <#T##String#>, mode: <#T##String?#>)
//        let str = "YjYxM2EzNTQzYTNjMDAzYjdjYjUzNzY3NTE2ZTk2ODdjNGJiMmUwMmNhNTUyYjllYjM4ZWRkODE0NGYyZGI0YjQyYjc4M2E4MzIxODlkNzc4YzFjMmNhNTFiNDVhNTU3"
//        let data = Data(base64Encoded: str, options: [])
//        
//        
//        
//    }
    func testImportKeyForNewUser() async throws {
        let email = "faker@gmail.com"
        let token = try generateIdToken(email: email)
        let privKeyBuffer = generatePrivateExcludingIndexes(shareIndexes: [])
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoints = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: email)
        let sssEndpoints = endpoints.torusNodeSSSEndpoints
        let verifierParams = VerifierParams(verifier_id: email)
        
        let response = try await torus?.importPrivateKey(endpoints: sssEndpoints, nodeIndexes: endpoints.torusIndexes, nodePubKeys: endpoints.torusNodePub.map( TorusNodePubModelToINodePub) , verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token, newPrivateKey: privKeyBuffer.serialize().toHexString() )
        
        XCTAssertEqual(response?.privKey.lowercased(), privKeyBuffer.serialize().toHexString().lowercased())
    }
    
    
    func testImporKeyForExistingUser() async throws {
        let email = TORUS_IMPORT_EMAIL
        let token = try generateIdToken(email: email)
        let privKeyBuffer = generatePrivateExcludingIndexes(shareIndexes: [])
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoints = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: email)
        let sssEndpoints = endpoints.torusNodeSSSEndpoints
        let verifierParams = VerifierParams(verifier_id: email)
        
        let publicAddress = try await torus?.getPublicAddress(endpoints: sssEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: email)
        
        let response = try await torus?.importPrivateKey(endpoints: sssEndpoints, nodeIndexes: endpoints.torusIndexes, nodePubKeys: endpoints.torusNodePub.map( TorusNodePubModelToINodePub) , verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token, newPrivateKey: privKeyBuffer.serialize().toHexString() )
        
        
        XCTAssertEqual(response?.privKey.lowercased(), privKeyBuffer.serialize().toHexString().lowercased())
        
        
        let publicAddressNew = try await torus?.getPublicAddressExtended(endpoints: sssEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: email)
        XCTAssertEqual(publicAddressNew?.address.lowercased(), response?.ethAddress.lowercased())
        XCTAssertNotEqual(publicAddressNew?.address.lowercased(), publicAddress?.lowercased())
        
    }

    func testPubAdderessOfTssVerifierId() async throws {
        let email = TORUS_EXTENDED_VERIFIER_EMAIL
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let nodes = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: email)
        let sssEndpoints = nodes.torusNodeSSSEndpoints
        
        let pubAddress = try await torus?.getPublicAddress(endpoints: sssEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, extendedVerifierId: tssVerifierId)
        XCTAssertEqual(pubAddress?.lowercased(), "0xBd6Bc8aDC5f2A0526078Fd2016C4335f64eD3a30".lowercased())
        
        let pubAddress2 = try await torus?.getPublicAddress(endpoints: sssEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, extendedVerifierId: tssVerifierId)
        XCTAssertEqual(pubAddress?.lowercased(), pubAddress2?.lowercased())
        
    }
    
    func testAssignKeyToTssVerifier() async throws {
        // fixme
        let email = TORUS_TEST_EMAIL //faker random address
        let verifierId = TORUS_TEST_EMAIL //faker random address
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: verifierId)
        let publicAddress = try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_VERIFIER, verifierId: verifierId)

        XCTAssertNotEqual(publicAddress, nil)
        XCTAssertNotEqual(publicAddress, "")
    }
    
    func testAllowTssVerifierIdFetchShare () async throws {
        
        let email = TORUS_TEST_EMAIL //faker random address ???
        let verifierId = TORUS_TEST_EMAIL
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        
        let token = try generateIdToken(email: email)
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: verifierId)
        let verifierParams = VerifierParams(verifier_id: verifierId, extended_verifier_id: tssVerifierId)
        
        try await torus?.retrieveShares(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_EMAIL, verifierParams: verifierParams, idToken: token)
    }
//
//     it("should allow test tss verifier id to fetch shares", async function () {
//       const email = faker.internet.email();
//       const nonce = 0;
//       const tssTag = "default";
//       const tssVerifierId = `${email}\u0015${tssTag}\u0016${nonce}`;
//       const token = generateIdToken(email, "ES256");
//       const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails({ verifierId: email, verifier: TORUS_TEST_VERIFIER });
//       const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//       await torus.retrieveShares(torusNodeEndpoints, TORUS_TEST_VERIFIER, { extended_verifier_id: tssVerifierId, verifier_id: email }, token);
//     });
    
    func testFetchPubAdderessWhenHashEnabled () async throws {
        
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: HashEnabledVerifier)
        let result = try await torus?.getPublicAddress(endpoints: endpoint.torusNodeSSSEndpoints, verifier: HashEnabledVerifier, verifierId: TORUS_TEST_EMAIL)
        
        XCTAssertEqual(result?.lowercased(), "0xF79b5ffA48463eba839ee9C97D61c6063a96DA03".lowercased())
    }

    func testLoginWhenHashEnabled () async throws {
        let email = TORUS_TEST_EMAIL
        let token = try generateIdToken(email: email)
        let verifierParams = VerifierParams(verifier_id: email )
        
        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
        let endpoint = try await nodeManager.getNodeDetails(verifier: HashEnabledVerifier, verifierID: HashEnabledVerifier)
        
        let result = try await torus?.retrieveShares(endpoints: endpoint.torusNodeSSSEndpoints, verifier: HashEnabledVerifier, verifierParams: verifierParams, idToken: token )
        XCTAssertEqual(result?.privKey.lowercased(), "066270dfa345d3d0415c8223e045f366b238b50870de7e9658e3c6608a7e2d32".lowercased())
    }
    
//    func testAggregrateLogin() async throws {
//        let email = TORUS_TEST_EMAIL // faker
//        let idToken = try generateIdToken(email: email)
//        let hashedIdToken = keccak256Data()
//
//        let nodeManager = NodeDetailManager(network: .SAPPHIRE_DEVNET)
//        let endpoint = try await nodeManager.getNodeDetails(verifier: HashEnabledVerifier, verifierID: HashEnabledVerifier)
//
//        let verifierParams = VerifierParams(verifier_id: email,
//                                            additionalParams: [
//            "sub_verifier_ids" : [TORUS_TEST_VERIFIER]
//        let result = try await torus?.retrieveShares(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierParams: VerifierParams, idToken: idToken )
//    }
    
    
    
//
//     // to do: update pub keys
//     it.skip("should lookup return hash when verifierID hash enabled", async function () {
//       const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails({ verifier: HashEnabledVerifier, verifierId: TORUS_TEST_VERIFIER });
//       const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//       for (const endpoint of torusNodeEndpoints) {
//         const pubKeyX = "21cd0ae3168d60402edb8bd65c58ff4b3e0217127d5bb5214f03f84a76f24d8a";
//         const pubKeyY = "575b7a4d0ef9921b3b1b84f30d412e87bc69b4eab83f6706e247cceb9e985a1e";
//         const response = await lookupVerifier(endpoint, pubKeyX, pubKeyY);
//         const verifierID = response.result.verifiers[HashEnabledVerifier][0];
//         expect(verifierID).to.equal("086c23ab78578f2fce9a1da11c0071ec7c2225adb1bf499ffaee98675bee29b7");
//       }
//     });
//
//     it("should fetch user type and public address when verifierID hash enabled", async function () {
//       const verifierDetails = { verifier: HashEnabledVerifier, verifierId: TORUS_TEST_EMAIL };
//       const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails(verifierDetails);
//       const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//       const { address } = (await torus.getPublicAddress(torusNodeEndpoints, verifierDetails, true)) as TorusPublicKey;
//       expect(address).to.equal("0xF79b5ffA48463eba839ee9C97D61c6063a96DA03");
//     });
//     it("should be able to login when verifierID hash enabled", async function () {
//       const token = generateIdToken(TORUS_TEST_EMAIL, "ES256");
//       const verifierDetails = { verifier: HashEnabledVerifier, verifierId: TORUS_TEST_EMAIL };
//
//       const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails(verifierDetails);
//       const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//       const retrieveSharesResponse = await torus.retrieveShares(torusNodeEndpoints, HashEnabledVerifier, { verifier_id: TORUS_TEST_EMAIL }, token);
//
//       expect(retrieveSharesResponse.privKey).to.be.equal("066270dfa345d3d0415c8223e045f366b238b50870de7e9658e3c6608a7e2d32");
//     });
//
//     it("should be able to aggregate login", async function () {
//       const email = faker.internet.email();
//       const idToken = generateIdToken(email, "ES256");
//       const hashedIdToken = keccak256(Buffer.from(idToken, "utf8"));
//       const verifierDetails = { verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: email };
//
//       const nodeDetails = await TORUS_NODE_MANAGER.getNodeDetails(verifierDetails);
//       const torusNodeEndpoints = nodeDetails.torusNodeSSSEndpoints;
//       const retrieveSharesResponse = await torus.retrieveShares(
//         torusNodeEndpoints,
//         TORUS_TEST_AGGREGATE_VERIFIER,
//         {
//           verify_params: [{ verifier_id: email, idtoken: idToken }],
//           sub_verifier_ids: [TORUS_TEST_VERIFIER],
//           verifier_id: email,
//         },
//         hashedIdToken.substring(2)
//       );
//       expect(retrieveSharesResponse.ethAddress).to.not.equal(null);
//       expect(retrieveSharesResponse.ethAddress).to.not.equal("");
//     });
}
