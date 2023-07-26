import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import web3
import XCTest
import CommonSources

import CoreMedia
@testable import TorusUtils

class TestnetTest: XCTestCase {
    var TORUS_TEST_EMAIL = "archit1@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager( network: .legacy(.TESTNET))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost, network: .legacy(.TESTNET))
        return nodeDetails
    }

    func test_get_public_address() async {
        let exp1 = XCTestExpectation(description: "should fetch public address")
        let verifier: String = "google-lrc"
        let verifierID: String = TORUS_TEST_EMAIL
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0x9bcBAde70546c0796c00323CD1b97fa0a425A506")
            XCTAssertEqual(val.finalKeyData!.X, "894f633b3734ddbf08867816bc55da60803c1e7c2a38b148b7fb2a84160a1bb5")
            XCTAssertEqual(val.finalKeyData!.Y, "1cf2ea7ac63ee1a34da2330413692ba8538bf7cd6512327343d918e0102a1438")
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x9bcBAde70546c0796c00323CD1b97fa0a425A506")
            XCTAssertEqual(val.oAuthKeyData!.X, "894f633b3734ddbf08867816bc55da60803c1e7c2a38b148b7fb2a84160a1bb5")
            XCTAssertEqual(val.oAuthKeyData!.Y, "1cf2ea7ac63ee1a34da2330413692ba8538bf7cd6512327343d918e0102a1438")
            XCTAssertNil(val.metadata?.pubNonce)
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_getUserTypeAndAddress_testnet() async {
        let exp1 = XCTestExpectation(description: "should fetch user type and public address")
        let exp2 = XCTestExpectation(description: "should fetch user type and public address")
        let exp3 = XCTestExpectation(description: "should fetch user type and public address")
        var verifier: String = "google-lrc"
        var verifierID: String = TORUS_TEST_EMAIL
        do {
            var nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x9bcBAde70546c0796c00323CD1b97fa0a425A506")
            XCTAssertEqual(val.oAuthKeyData!.X, "894f633b3734ddbf08867816bc55da60803c1e7c2a38b148b7fb2a84160a1bb5")
            XCTAssertEqual(val.oAuthKeyData!.Y, "1cf2ea7ac63ee1a34da2330413692ba8538bf7cd6512327343d918e0102a1438")
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0xf5804f608C233b9cdA5952E46EB86C9037fd6842")
            XCTAssertEqual(val.finalKeyData!.X, "ed737569a557b50722a8b5c0e4e5ca30cef1ede2f5674a0616b78246bb93dfd0")
            XCTAssertEqual(val.finalKeyData!.Y, "d9e8e6c54c12c4da38c2f0d1047fcf6089036127738f4ef72a83431339586ca9")
            XCTAssertEqual(val.metadata?.pubNonce?.x, "f3f7caefd6540d923c9993113f34226371bd6714a5be6882dedc95a6a929a8")
            XCTAssertEqual(val.metadata?.pubNonce?.y, "f28620603601ce54fa0d70fd691fb72ff52f5bf164bf1a91617922eaad8cc7a5")
            XCTAssertEqual(val.metadata?.nonce, 0)
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, .v2)
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()

        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()

        }
    }

    func test_key_assign_testnet() async {
        let exp1 = XCTestExpectation(description: "should be able to key assign")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "google-lrc"
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertNotNil(data.finalKeyData)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_login_aqua() async {
        let exp1 = XCTestExpectation(description: "should be able to login")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares( endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)

            XCTAssertEqual(data.finalKeyData?.evmAddress, "0xF8d2d3cFC30949C1cb1499C9aAC8F9300535a8d6")
            XCTAssertEqual(data.finalKeyData?.X, "6de2e34d488dd6a6b596524075b032a5d5eb945bcc33923ab5b88fd4fd04b5fd")
            XCTAssertEqual(data.finalKeyData?.Y, "d5fb7b51b846e05362461357ec6e8ca075ea62507e2d5d7253b72b0b960927e9")
            XCTAssertEqual(data.finalKeyData?.privKey, "9b0fb017db14a0a25ed51f78a258713c8ae88b5e58a43acb70b22f9e2ee138e3")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0xF8d2d3cFC30949C1cb1499C9aAC8F9300535a8d6")
            XCTAssertEqual(data.oAuthKeyData?.X, "6de2e34d488dd6a6b596524075b032a5d5eb945bcc33923ab5b88fd4fd04b5fd")
            XCTAssertEqual(data.oAuthKeyData?.Y, "d5fb7b51b846e05362461357ec6e8ca075ea62507e2d5d7253b72b0b960927e9")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "9b0fb017db14a0a25ed51f78a258713c8ae88b5e58a43acb70b22f9e2ee138e3")
            XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce, nil)
            XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            XCTAssertEqual(data.metadata?.upgraded, nil)
            XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
            
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }

    func test_aggregate_login_aqua() async throws {
        let exp1 = XCTestExpectation(description: "should be able to aggregate login")
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x5b58d8a16fDA79172cd42Dc3068d5CEf26a5C81D")
            XCTAssertEqual(data.finalKeyData?.X, "37a4ac8cbef68e88bcec5909d9b6fffb539187365bb723f3d7bffe56ae80e31d")
            XCTAssertEqual(data.finalKeyData?.Y, "f963f2d08ed4dd0da9b8a8d74c6fdaeef7bdcde31f84fcce19fa2173d40b2c10")
            XCTAssertEqual(data.finalKeyData?.privKey, "488d39ac548e15cfb0eaf161d86496e1645b09437df21311e24a56c4efd76355")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x5b58d8a16fDA79172cd42Dc3068d5CEf26a5C81D")
            XCTAssertEqual(data.oAuthKeyData?.X, "37a4ac8cbef68e88bcec5909d9b6fffb539187365bb723f3d7bffe56ae80e31d")
            XCTAssertEqual(data.oAuthKeyData?.Y, "f963f2d08ed4dd0da9b8a8d74c6fdaeef7bdcde31f84fcce19fa2173d40b2c10")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "488d39ac548e15cfb0eaf161d86496e1645b09437df21311e24a56c4efd76355")
            XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce, nil)
            XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
            XCTAssertEqual(data.metadata?.typeOfUser, .v1)
            XCTAssertEqual(data.metadata?.upgraded, nil)
            XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}

extension TestnetTest {
    func test_retrieveShares_some_nodes_down() async {
        let exp1 = XCTestExpectation(description: "Should be able to getPublicAddress")
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let buffer: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        do {
            let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
            var endpoints = nodeDetails.getTorusNodeEndpoints()
            endpoints[0] =    "https://ndjnfjbfrj/random"
            // should fail if un-commented threshold 4/5
            // endpoints[1] = "https://ndjnfjbfrj/random"
            let data = try await tu.retrieveShares(endpoints: endpoints, torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
            XCTAssertEqual(data.finalKeyData?.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
}
