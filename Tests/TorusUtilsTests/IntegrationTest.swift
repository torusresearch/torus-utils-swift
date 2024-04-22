import BigInt
import FetchNodeDetails
import JWTKit
import XCTest

@testable import TorusUtils

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

    // Fake data
    let TORUS_TEST_VERIFIER_FAKE = "google-lrc-fakes"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager(network: .legacy(.TESTNET))
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.TESTNET), clientId: "YOUR_CLIENT_ID")
        return nodeDetails
    }

    func test_getPublicAddress() async throws {
        var nodeDetails = try await get_fnd_and_tu_data(verifer: "google-lrc", veriferID: TORUS_TEST_EMAIL)
        let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: "google-lrc", verifierId: "hello@tor.us")
        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x872eEfa7495599A6983d396fE8dcf542457CF33f")

        do {
            nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER_FAKE, veriferID: TORUS_TEST_EMAIL)
            _ = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER_FAKE, verifierId: TORUS_TEST_EMAIL)
        } catch _ {
        }
    }

    func test_getUserTypeAndAddress() async throws {
        let verifier: String = "tkey-google-lrc"
        let verifierID: String = "somev2user@gmail.com"
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)

        XCTAssertEqual(val.finalKeyData?.evmAddress, "0xE91200d82029603d73d6E307DbCbd9A7D0129d8D")
    }

/* TODO: Investigate this further
    func test_keyAssign() async throws {
        let email = generateRandomEmail(of: 6)

        let nodeDetails = try await get_fnd_and_tu_data(verifer: "google-lrc", veriferID: email)
        let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: email, signerHost: tu.signerHost, network: .legacy(.TESTNET))
        guard let result = val.result as? [String: Any] else {
            throw TorusUtilError.empty
        }
        let keys = result["keys"] as! [[String: String]]
        _ = keys[0]["address"]

        // Add more check to see if address is valid
    }
*/
    
    func test_keyLookup() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: "google-lrc", verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(val.address, "0x872eEfa7495599A6983d396fE8dcf542457CF33f")

        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            _ = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: "google-lrc-fake", verifierId: TORUS_TEST_EMAIL)
            XCTFail()
        } catch let error {
            if let keylookupError = error as? KeyLookupError {
                XCTAssertEqual(keylookupError, KeyLookupError.verifierNotSupported)
            }
        }
    }

    // MARK: Aggregate tests

    func test_getPublicAddressAggregateLogin() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(val.finalKeyData?.evmAddress, "0x5a165d2Ed4976BD104caDE1b2948a93B72FA91D2")
    }

    /* TODO: Investigate this test further
    func test_keyAssignAggregateLogin() async throws {
        let email = generateRandomEmail(of: 6)

        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: email, signerHost: signerHost, network: .legacy(.TESTNET))
        guard let result = val.result as? [String: Any] else {
            throw TorusUtilError.empty
        }
        let keys = result["keys"] as! [[String: String]]
        _ = keys[0]["address"]

        // Add more check to see if address is valid
    }
    */

    func test_keyLookupAggregateLogin() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.keyLookup(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_AGGREGATE_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(val.address, "0x5a165d2Ed4976BD104caDE1b2948a93B72FA91D2")
    }
}

extension IntegrationTests {}

struct ROPSTEN_CONSTANTS {
    static let endpoints = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]
    static let nodePubKeys = [TorusNodePubModel(_X: "1363aad8868cacd7f8946c590325cd463106fb3731f08811ab4302d2deae35c3", _Y: "d77eebe5cdf466b475ec892d5b4cffbe0c1670525debbd97eee6dae2f87a7cbe"), TorusNodePubModel(_X: "7c8cc521c48690f016bea593f67f88ad24f447dd6c31bbab541e59e207bf029d", _Y: "b359f0a82608db2e06b953b36d0c9a473a00458117ca32a5b0f4563a7d539636"), TorusNodePubModel(_X: "8a86543ca17df5687719e2549caa024cf17fe0361e119e741eaee668f8dd0a6f", _Y: "9cdb254ff915a76950d6d13d78ef054d5d0dc34e2908c00bb009a6e4da701891"), TorusNodePubModel(_X: "25a98d9ae006aed1d77e81d58be8f67193d13d01a9888e2923841894f4b0bf9c", _Y: "f63d40df480dacf68922004ed36dbab9e2969181b047730a5ce0797fb6958249"), TorusNodePubModel(_X: "d908f41f8e06324a8a7abcf702adb6a273ce3ae63d86a3d22723e1bbf1438c9a", _Y: "f977530b3ec0e525438c72d1e768380cbc5fb3b38a760ee925053b2e169428ce")]
}
