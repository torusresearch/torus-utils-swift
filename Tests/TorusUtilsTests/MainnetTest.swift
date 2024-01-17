import BigInt
import FetchNodeDetails
import JWTKit
import XCTest

import CommonSources

@testable import TorusUtils

class MainnetTests: XCTestCase {
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
        fnd = NodeDetailManager(network: .legacy(.MAINNET))
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        tu = TorusUtils(enableOneKey: enableOneKey, network: .legacy(.MAINNET))
        return nodeDetails
    }

    func test_get_public_address() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: "google", veriferID: TORUS_TEST_EMAIL)
        let val = try await tu.getPublicAddress(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub, verifier: "google", verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
        XCTAssertEqual(val.finalKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
        XCTAssertEqual(val.finalKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
        XCTAssertEqual(val.oAuthKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
        XCTAssertEqual(val.oAuthKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
        XCTAssertNil(val.metadata?.pubNonce)
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
        XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
    }

    func test_fetch_user_type_and_addresses() async throws {
        let verifier1: String = "google"
        let verifierID1: String = TORUS_TEST_EMAIL
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        var val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier1, verifierId: verifierID1)

        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
        XCTAssertEqual(val.finalKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
        XCTAssertEqual(val.finalKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x0C44AFBb5395a9e8d28DF18e1326aa0F16b9572A")
        XCTAssertEqual(val.oAuthKeyData!.X, "3b5655d78978b6fd132562b5cb66b11bcd868bd2a9e16babe4a1ca50178e57d4")
        XCTAssertEqual(val.oAuthKeyData!.Y, "15338510798d6b55db28c121d86babcce19eb9f1882f05fae8ee9b52ed09e8f1")
        XCTAssertNil(val.metadata?.pubNonce)
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
        XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)

        let verifier2: String = "tkey-google"
        let verifierID2: String = "somev2user@gmail.com"
        val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier2, verifierId: verifierID2)

        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xA9c6829e4899b6D630130ebf59D046CA868D7f83")
        XCTAssertEqual(val.oAuthKeyData!.X, "5566cd940ea540ba1a3ba2ff0f5fd3d9a3a74350ac3baf47b811592ae6ea1c30")
        XCTAssertEqual(val.oAuthKeyData!.Y, "07a302e87e8d9eb5d143f570c248657288c13c09ecbe1e3a8720449daf9315b0")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0xFf669A15bFFcf32D3C5B40bE9E5d409d60D43526")
        XCTAssertEqual(val.finalKeyData!.X, "bbfd26b1e61572c4e991a21b64f12b313cb6fce6b443be92d4d5fd8f311e8f33")
        XCTAssertEqual(val.finalKeyData!.Y, "df2c905356ec94faaa111a886be56ed6fa215b7facc1d1598486558355123c25")
        XCTAssertEqual(val.metadata?.pubNonce?.x, "96f4b7d3c8c8c69cabdea46ae1eedda346b03cad8ba1a454871b0ec6a69861f3")
        XCTAssertEqual(val.metadata?.pubNonce?.y, "da3aed7f7e9d612052beb1d92ec68a8dcf60faf356985435b424af2423f66672")
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
        XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)

        let verifier3: String = "tkey-google"
        let verifierID3: String = "caspertorus@gmail.com"
        val = try await tu.getUserTypeAndAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier3, verifierId: verifierID3)

        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x61E52B6e488EC3dD6FDc0F5ed04a62Bb9c6BeF53")
        XCTAssertEqual(val.finalKeyData!.X, "c01282dd68d2341031a1cff06f70d821cad45140f425f1c25055a8aa64959df8")
        XCTAssertEqual(val.finalKeyData!.Y, "cb3937773bb819d60b780b6d4c2edcf27c0f7090ba1fc2ff42504a8138a8e2d7")
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x61E52B6e488EC3dD6FDc0F5ed04a62Bb9c6BeF53")
        XCTAssertEqual(val.oAuthKeyData!.X, "c01282dd68d2341031a1cff06f70d821cad45140f425f1c25055a8aa64959df8")
        XCTAssertEqual(val.oAuthKeyData!.Y, "cb3937773bb819d60b780b6d4c2edcf27c0f7090ba1fc2ff42504a8138a8e2d7")
        XCTAssertEqual(val.metadata?.pubNonce?.x, nil)
        XCTAssertEqual(val.metadata?.pubNonce?.y, nil)
        XCTAssertEqual(val.metadata?.nonce, 0)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v1"))
        XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
    }

    func test_key_assign() async throws {
        let email = generateRandomEmail(of: 6)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: "google", veriferID: email)
        let val = try await tu.keyAssign(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: email, signerHost: tu.signerHost, network: .legacy(.MAINNET))
        guard let result = val.result as? [String: Any] else {
            throw TorusUtilError.empty
        }
        let keys = result["keys"] as! [[String: String]]
        _ = keys[0]["address"]

        // Add more check to see if address is valid
    }

    func test_login() async throws {
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let extraParams = ["verifieridentifier": TORUS_TEST_VERIFIER, "verifier_id": TORUS_TEST_EMAIL] as [String: Codable]
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
        let data = try await tu.retrieveShares(
            endpoints: nodeDetails.getTorusNodeEndpoints(),
            torusNodePubs: nodeDetails.getTorusNodePub(),
            indexes: nodeDetails.getTorusIndexes(),
            verifier: TORUS_TEST_VERIFIER,
            verifierParams: verifierParams,
            idToken: jwt,
            extraParams: extraParams)

        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x90A926b698047b4A87265ba1E9D8b512E8489067")
        XCTAssertEqual(data.finalKeyData?.X, "a92d8bf1f01ad62e189a5cb0f606b89aa6df1b867128438c38e3209f3b9fc34f")
        XCTAssertEqual(data.finalKeyData?.Y, "0ad1ffaecb2178b02a37c455975368be9b967ead1b281202cc8d48c77618bff1")
        XCTAssertEqual(data.finalKeyData?.privKey, "0129494416ab5d5f674692b39fa49680e07d3aac01b9683ee7650e40805d4c44")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x90A926b698047b4A87265ba1E9D8b512E8489067")
        XCTAssertEqual(data.oAuthKeyData?.X, "a92d8bf1f01ad62e189a5cb0f606b89aa6df1b867128438c38e3209f3b9fc34f")
        XCTAssertEqual(data.oAuthKeyData?.Y, "0ad1ffaecb2178b02a37c455975368be9b967ead1b281202cc8d48c77618bff1")
        XCTAssertEqual(data.oAuthKeyData?.privKey, "0129494416ab5d5f674692b39fa49680e07d3aac01b9683ee7650e40805d4c44")
        XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(data.metadata?.pubNonce, nil)
        XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
        XCTAssertEqual(data.metadata?.typeOfUser, .v1)
        XCTAssertEqual(data.metadata?.upgraded, nil)
        XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
    }

    func test_aggregate_login() async throws {
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = TORUS_TEST_EMAIL
        let jwt = try! generateIdToken(email: TORUS_TEST_EMAIL)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": TORUS_TEST_EMAIL, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": TORUS_TEST_EMAIL, "idtoken": jwt]]] as [String: Codable]
        let verifierParams = VerifierParams(verifier_id: verifierID)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)

        let data = try await tu.retrieveShares(endpoints: nodeDetails.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub, indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)

        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x621a4d458cFd345dAE831D9E756F10cC40A50381")
        XCTAssertEqual(data.finalKeyData?.X, "52abc69ebec21deacd273dbdcb4d40066b701177bba906a187676e3292e1e236")
        XCTAssertEqual(data.finalKeyData?.Y, "5e57e251db2c95c874f7ec852439302a62ef9592c8c50024e3d48018a6f77c7e")
        XCTAssertEqual(data.finalKeyData?.privKey, "f55d89088a0c491d797c00da5b2ed6dc9c269c960ff121e45f255d06a91c6534")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x621a4d458cFd345dAE831D9E756F10cC40A50381")
        XCTAssertEqual(data.oAuthKeyData?.X, "52abc69ebec21deacd273dbdcb4d40066b701177bba906a187676e3292e1e236")
        XCTAssertEqual(data.oAuthKeyData?.Y, "5e57e251db2c95c874f7ec852439302a62ef9592c8c50024e3d48018a6f77c7e")
        XCTAssertEqual(data.oAuthKeyData?.privKey, "f55d89088a0c491d797c00da5b2ed6dc9c269c960ff121e45f255d06a91c6534")
        XCTAssertEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(data.metadata?.pubNonce, nil)
        XCTAssertEqual(data.metadata?.nonce, BigUInt(0))
        XCTAssertEqual(data.metadata?.typeOfUser, .v1)
        XCTAssertEqual(data.metadata?.upgraded, nil)
        XCTAssertEqual(data.nodesData?.nodeIndexes.count, 0)
    }
}
