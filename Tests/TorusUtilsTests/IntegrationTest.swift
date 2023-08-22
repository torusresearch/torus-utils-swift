import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import XCTest

import CommonSources

@testable import TorusUtils

@available(iOS 13.0, *)
class IntegrationTests: XCTestCase {
    static var fetchNodeDetails: AllNodeDetailsModel?
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
    var fnd: NodeDetailManager!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
//        fnd = FetchNodeDetails(proxyAddress: FetchNodeDetails.proxyAddressTestnet, network: .TESTNET)
        fnd = NodeDetailManager(network: .legacy(.TESTNET))
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.TESTNET))
        return nodeDetails
    }

    func test_getPublicAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: "google-lrc", veriferID: TORUS_TEST_EMAIL)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: "google-lrc", verifierId: "hello@tor.us")
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x5b56E06009528Bffb1d6336575731ee3B63f6150")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }

        let exp2 = XCTestExpectation(description: "Should throw if verifier not supported")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER_FAKE, veriferID: TORUS_TEST_EMAIL)
            _ = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER_FAKE, verifierId: TORUS_TEST_EMAIL)
            XCTFail()
        } catch _ {
            exp2.fulfill()
        }
    }

    func test_getUserTypeAndAddress() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = "tkey-google-lrc"
        let verifierID: String = "somev2user@gmail.com"
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)

            XCTAssertEqual(val.finalKeyData?.evmAddress, "0xE91200d82029603d73d6E307DbCbd9A7D0129d8D")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_keyAssign() async {
        let email = generateRandomEmail(of: 6)

        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: "google-lrc", veriferID: email)
            let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: email, signerHost: tu.signerHost, network: .legacy(.TESTNET))
            let result = val.result as! [String: Any]
            let keys = result["keys"] as! [[String: String]]
            let address = keys[0]["address"]

            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_keyLookup() async {
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL)
            XCTAssertEqual(val.address, "0x5b56E06009528Bffb1d6336575731ee3B63f6150")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }

        let exp2 = XCTestExpectation(description: "Should not be able to do keylookup")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: "google-lrc-fake", verifierId: TORUS_TEST_EMAIL)
          XCTFail()
        } catch let error {
            if let keylookupError = error as? KeyLookupError {
                XCTAssertEqual(keylookupError, KeyLookupError.verifierNotSupported)

            }
            exp2.fulfill()
        }
    }

//    func test_shouldLogin() async {
//        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
//        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
//        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
//        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Codable]
//        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
//        do {
//            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
//            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(),  verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
//            XCTAssertEqual(data.privKey, "068ee4f97468ef1ae95d18554458d372e31968190ae38e377be59d8b3c9f7a25")
//            exp1.fulfill()
//        } catch let error {
//            XCTFail(error.localizedDescription)
//            exp1.fulfill()
//        }
//    }

    // MARK: Aggregate tests

    func test_getPublicAddressAggregateLogin() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL)
            XCTAssertEqual(val.finalKeyData?.evmAddress, "0x5a165d2Ed4976BD104caDE1b2948a93B72FA91D2")
            exp1.fulfill()
        } catch let error {
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_keyAssignAggregateLogin() async {
        let email = generateRandomEmail(of: 6)

        let exp1 = XCTestExpectation(description: "Should be able to do a keyAssign")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: email, signerHost: signerHost, network: .legacy(.TESTNET))
            let result = val.result as! [String: Any]
            let keys = result["keys"] as! [[String: String]]
            let address = keys[0]["address"]

            // Add more check to see if address is valid
            XCTAssertNotNil(address)
            exp1.fulfill()
        } catch let error {
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_keyLookupAggregateLogin() async {
        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookupAggregateLogin")
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            let val = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL)
            XCTAssertEqual(val.address, "0x5a165d2Ed4976BD104caDE1b2948a93B72FA91D2")
            exp1.fulfill()
        } catch let error {
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }

//    func test_shouldAggregateLogin() async {
//        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
//        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
//        let verifierID: String = TORUS_TEST_EMAIL
//        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
//        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
//        let hashedIDToken = jwt.sha3(.keccak256)
//        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
//        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
//        do {
//            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
//            let val = try await tu.retrieveShares( endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(),  verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
//            XCTAssertEqual(val.ethAddress, "0x5a165d2Ed4976BD104caDE1b2948a93B72FA91D2")
//            exp1.fulfill()
//        } catch let err {
//            XCTFail(err.localizedDescription)
//            exp1.fulfill()
//        }
//    }
}

extension IntegrationTests {

//    func test_retrieveShares_timeout() async {
//        // change the timeout variable in TorusUtil to 0 the test should fail
//        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
//        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
//        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Any]
//        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
//        do {
//            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
//            var endpoints = nodeDetails.getTorusNodeEndpoints()
//            endpoints[0] = "https://ndjnfjbfrj/random"
//            // should fail if un-commented threshold 4/5
//            // endpoints[1] = "https://ndjnfjbfrj/random"
//            let data = try await tu.handleRetrieveShares(torusNodePubs: nodeDetails.getTorusNodePub(), endpoints: endpoints, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, idToken: jwt, extraParams: buffer)
//            XCTAssertEqual(data.privateKey, "068ee4f97468ef1ae95d18554458d372e31968190ae38e377be59d8b3c9f7a25")
//            exp1.fulfill()
//        } catch let error {
//            XCTFail(error.localizedDescription)
//            exp1.fulfill()
//        }
//    }
//
//    func test_retrieveShares_some_nodes_down() async {
//        let exp1 = XCTestExpectation(description: "Should be able to do a Login")
//        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
//        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
//        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Codable]
//        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
//        do {
//            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
//            var endpoints = nodeDetails.getTorusNodeEndpoints()
//            endpoints[0] = "https://ndjnfjbfrj/random"
//            // should fail if un-commented threshold 4/5
//          // endpoints[1] = "https://ndjnfjbfrj/random"
//            let data = try await tu.retrieveShares(endpoints: endpoints, torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
//            XCTAssertEqual(data.privKey, "068ee4f97468ef1ae95d18554458d372e31968190ae38e377be59d8b3c9f7a25")
//            exp1.fulfill()
//        } catch let error {
//            XCTFail(error.localizedDescription)
//            exp1.fulfill()
//        }
//    }
//
//    func test_keyLookup_some_nodes_down() async {
//
//        let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
//        do {
//            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
//            var endpoints = nodeDetails.getTorusNodeEndpoints()
//            endpoints[0] = "https://ndjnfjbfrj/random"
//            endpoints[1] = "https://ndjnfjbfrj/random"
//            // should fail if un-commented threshold 3/5 in case of key lookup
//           //  endpoints[2] = "https://ndjnfjbfrj/random"
//            let val = try await tu.keyLookup(endpoints: endpoints, verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL)
//            XCTAssertEqual(val.address, "0xFf5aDad69F4e97AF4D4567e7C333C12df6836a70")
//            exp1.fulfill()
//        } catch let err {
//            XCTFail(err.localizedDescription)
//            exp1.fulfill()
//        }
//    }

    func test_keyLookup_some_nodes_waiting() async {

         let exp1 = XCTestExpectation(description: "Should be able to do a keyLookup")
         do {
             let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
             var endpoints = nodeDetails.getTorusNodeEndpoints()

             // should fail if un-commented threshold 3/5 in case of key lookup

              endpoints = ["https://node-1.torus-cluster-1.com/jrpc",
                             "https://node-2.torus-cluster-1.com/jrpc",
                             "https://node-3.torus-cluster-1.com/jrpc",
                             "https://node-4.torus-cluster-1.com/jrpc",
                             "https://node-5.torus-cluster-1.com/jrpc"]
             let val = try await tu.keyLookup(endpoints: endpoints, verifier: "torus-test-health", verifierId: TORUS_TEST_EMAIL)
             XCTAssertEqual(val.address, "0x8AA6C8ddCD868873120aA265Fc63E3a2180375BA")
             exp1.fulfill()
         } catch let err {
             XCTFail(err.localizedDescription)
             exp1.fulfill()
         }
     }

}

struct ROPSTEN_CONSTANTS {
    static let endpoints = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]
    static let nodePubKeys = [TorusNodePubModel(_X: "1363aad8868cacd7f8946c590325cd463106fb3731f08811ab4302d2deae35c3", _Y: "d77eebe5cdf466b475ec892d5b4cffbe0c1670525debbd97eee6dae2f87a7cbe"), TorusNodePubModel(_X: "7c8cc521c48690f016bea593f67f88ad24f447dd6c31bbab541e59e207bf029d", _Y: "b359f0a82608db2e06b953b36d0c9a473a00458117ca32a5b0f4563a7d539636"), TorusNodePubModel(_X: "8a86543ca17df5687719e2549caa024cf17fe0361e119e741eaee668f8dd0a6f", _Y: "9cdb254ff915a76950d6d13d78ef054d5d0dc34e2908c00bb009a6e4da701891"), TorusNodePubModel(_X: "25a98d9ae006aed1d77e81d58be8f67193d13d01a9888e2923841894f4b0bf9c", _Y: "f63d40df480dacf68922004ed36dbab9e2969181b047730a5ce0797fb6958249"), TorusNodePubModel(_X: "d908f41f8e06324a8a7abcf702adb6a273ce3ae63d86a3d22723e1bbf1438c9a", _Y: "f977530b3ec0e525438c72d1e768380cbc5fb3b38a760ee925053b2e169428ce")]
}

extension IntegrationTests {
    func test_canStrip() {
        var a: String = "000123"
        a.stripPaddingLeft(padChar: "0")
        XCTAssertEqual("123", a)
    }
}
