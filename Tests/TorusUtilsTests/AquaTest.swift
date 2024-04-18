import BigInt
#if canImport(CommonSources)
    import CommonSources
#endif
import FetchNodeDetails
import JWTKit
import XCTest

import CoreMedia
@testable import TorusUtils

class AquaTest: XCTestCase {
    var TORUS_TEST_EMAIL = "hello@tor.us"
    var TORUS_TEST_VERIFIER = "torus-test-health"
    var TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    var fnd: NodeDetailManager!
    var tu: TorusUtils!
    var signerHost = "https://signer-polygon.tor.us/api/sign"
    var allowHost = "https://signer-polygon.tor.us/api/allow"

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager(network: .legacy(.AQUA))
    }

    func getFNDAndTUData(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, signerHost: signerHost, allowHost: allowHost, network: .legacy(.AQUA), clientId: "YOUR_CLIENT_ID")
        return nodeDetails
    }

    func test_should_fetch_public_address() async throws {
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = TORUS_TEST_EMAIL
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let val = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
        XCTAssertEqual(val.finalKeyData!.X, "4fc8db5d3fe164a3ab70fd6348721f2be848df2cc02fd2db316a154855a7aa7d")
        XCTAssertEqual(val.finalKeyData!.Y, "f76933cbf5fe2916681075bb6cb4cde7d5f6b6ce290071b1b7106747d906457c")
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
        XCTAssertEqual(val.oAuthKeyData!.X, "4fc8db5d3fe164a3ab70fd6348721f2be848df2cc02fd2db316a154855a7aa7d")
        XCTAssertEqual(val.oAuthKeyData!.Y, "f76933cbf5fe2916681075bb6cb4cde7d5f6b6ce290071b1b7106747d906457c")
        XCTAssertNil(val.metadata?.pubNonce)
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
    }

    func test_should_fetch_user_type_and_public_addresses() async throws {
        var verifier: String = "tkey-google-aqua"
        var verifierID: String = TORUS_TEST_EMAIL
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        var val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xDfA967285AC699A70DA340F60d00DB19A272639d")
        XCTAssertEqual(val.oAuthKeyData!.X, "4fc8db5d3fe164a3ab70fd6348721f2be848df2cc02fd2db316a154855a7aa7d")
        XCTAssertEqual(val.oAuthKeyData!.Y, "f76933cbf5fe2916681075bb6cb4cde7d5f6b6ce290071b1b7106747d906457c")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x79F06350eF34Aeed4BE68e26954D405D573f1438")
        XCTAssertEqual(val.finalKeyData!.X, "99df45abc8e6ee03d2f94df33be79e939eadfbed20c6b88492782fdc3ef1dfd3")
        XCTAssertEqual(val.finalKeyData!.Y, "12bf3e54599a177fdb88f8b22419df7ddf1622e1d2344301edbe090890a72b16")
        XCTAssertEqual(val.metadata!.pubNonce!.x, "dc5a031fd2e0b55dbaece314ea125bac9da5f0a916bf156ff36b5ad71380ea32")
        XCTAssertEqual(val.metadata!.pubNonce!.y, "affd749b98c209d2f9cf4dacb145d7897f82f1e2924a47b07874302ecc0b8ef1")
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, .v2)

        verifier = "tkey-google-aqua"
        verifierID = "somev2user@gmail.com"
        val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x4ea5260fF85678A2a326D08DF9C44d1f559a5828")
        XCTAssertEqual(val.oAuthKeyData!.X, "0e6febe33a9d4eeb680cc6b63ff6237ad1971f27adcd7f104a3b1de18eda9337")
        XCTAssertEqual(val.oAuthKeyData!.Y, "a5a915561f3543688e71281a850b9ee10b9690f305d9e79028dfc8359192b82d")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0xBc32f315515AdE7010cabC5Fd68c966657A570BD")
        XCTAssertEqual(val.finalKeyData!.X, "4897f120584ee18a72b9a6bb92c3ef6e45fc5fdff70beae7dc9325bd01332022")
        XCTAssertEqual(val.finalKeyData!.Y, "2066dbef2fcdded4573e3c04d1c04edd5d44662168e636ed9d0b0cbe2e67c968")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0xBc32f315515AdE7010cabC5Fd68c966657A570BD")
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, .v2)

        verifierID = "caspertorus@gmail.com"
        val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x4ce0D09C3989eb3cC9372cC27fa022D721D737dD")
        XCTAssertEqual(val.oAuthKeyData!.X, "e76d2f7fa2c0df324b4ab74629c3af47aa4609c35f1d2b6b90b77a47ab9a1281")
        XCTAssertEqual(val.oAuthKeyData!.Y, "b33b35148d72d357070f66372e07fec436001bdb15c098276b120b9ed64c1e5f")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x5469C5aCB0F30929226AfF4622918DA8E1424a8D")
        XCTAssertEqual(val.finalKeyData!.X, "c20fac685bb67169e92f1d5d8894d4eea18753c0ef3b7b1b2224233b2dfa3539")
        XCTAssertEqual(val.finalKeyData!.Y, "c4f080b5c8d5c55c8eaba4bec70f668f36db4126f358b491d631fefea7c19d21")
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, .v2)
    }

    func test_key_assign() async throws {
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = "tkey-google-aqua"
        let verifierID: String = fakeEmail
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertNotNil(data.finalKeyData)
        XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
        XCTAssertEqual(data.metadata?.typeOfUser, .v1)
        XCTAssertEqual(data.metadata?.upgraded, false)
    }

    func test_login() async throws {
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)

        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x9EBE51e49d8e201b40cAA4405f5E0B86d9D27195")
        XCTAssertEqual(data.finalKeyData?.X, "c7bcc239f0957bb05bda94757eb4a5f648339424b22435da5cf7a0f2b2323664")
        XCTAssertEqual(data.finalKeyData?.Y, "63795690a33e575ee12d832935d563c2b5f2e1b1ffac63c32a4674152f68cb3f")
        XCTAssertEqual(data.finalKeyData?.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x9EBE51e49d8e201b40cAA4405f5E0B86d9D27195")
        XCTAssertEqual(data.oAuthKeyData?.X, "c7bcc239f0957bb05bda94757eb4a5f648339424b22435da5cf7a0f2b2323664")
        XCTAssertEqual(data.oAuthKeyData?.Y, "63795690a33e575ee12d832935d563c2b5f2e1b1ffac63c32a4674152f68cb3f")
        XCTAssertEqual(data.oAuthKeyData?.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
        XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(data.metadata?.pubNonce, nil)
        XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
        XCTAssertEqual(data.metadata?.typeOfUser, .v1)
        XCTAssertEqual(data.metadata?.upgraded, nil)
    }

    func test_aggregate_login() async throws {
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken =  keccak256Data(jwt.data(using: .utf8) ?? Data()).toHexString();
        
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        let data = try await tu.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
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
        XCTAssertEqual(data.metadata?.pubNonce == nil, true)
        XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
        XCTAssertEqual(data.metadata?.typeOfUser == UserType.v1, true)
        XCTAssertEqual(data.metadata?.upgraded == nil, true)
    }
}

extension AquaTest {
    func test_retrieveShares_some_nodes_down() async throws {
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let jwt = try! generateIdToken(email: verifierID)
        let extraParams = ["verifieridentifier": verifier, "verifier_id": verifierID] as [String: Codable]
        let nodeDetails = try await getFNDAndTUData(verifer: verifier, veriferID: verifierID)
        var endpoints = nodeDetails.getTorusNodeEndpoints()
        endpoints[0] = "https://ndjnfjbfrj/random"
        // should fail if un-commented threshold 4/5
        // endpoints[1] = "https://ndjnfjbfrj/random"
        let data = try await tu.retrieveShares(endpoints: endpoints, torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: jwt, extraParams: extraParams)
        XCTAssertEqual(data.finalKeyData?.privKey, "f726ce4ac79ae4475d72633c94769a8817aff35eebe2d4790aed7b5d8a84aa1d")
    }
}
