import BigInt
import FetchNodeDetails
import JWTKit
import XCTest
import curveSecp256k1
import CommonSources

@testable import TorusUtils

final class SapphireTest: XCTestCase {
    static var fetchNodeDetails: AllNodeDetailsModel?
    // static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: [String] = []
    static var nodePubKeys: [TorusNodePubModel] = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "torus-test-health"
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    let TORUS_TEST_EMAIL = "devnettestuser@tor.us"
    let TORUS_HASH_ENABLED_TEST_EMAIL = "saasas@tr.us";
    let TORUS_IMPORT_EMAIL = "Sydnie.Lehner73@yahoo.com"
    let TORUS_EXTENDED_VERIFIER_EMAIL = "testextenderverifierid@example.com"
    let HashEnabledVerifier = "torus-test-verifierid-hash"

    var signerHost = "https://signer.tor.us/api/sign"
    var allowHost = "https://signer.tor.us/api/allow"

    var fnd: NodeDetailManager!
    var torus: TorusUtils!

    override func setUp() {
        super.setUp()
        fnd = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
    }

    func get_fnd_and_tu_data(verifer: String, veriferID: String, enableOneKey: Bool = false) async throws -> AllNodeDetailsModel {
        let nodeDetails = try await fnd.getNodeDetails(verifier: verifer, verifierID: veriferID)
        torus = TorusUtils(enableOneKey: enableOneKey, network: .sapphire(.SAPPHIRE_DEVNET), clientId: "YOUR_CLIENT_ID")
        return nodeDetails
    }

    func testFetchPublicAddress() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

        let val = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.torusNodePub, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0x137B3607958562D03Eb3C6086392D1eFa01aA6aa")
        XCTAssertEqual(val.oAuthKeyData!.X, "118a674da0c68f16a1123de9611ba655f4db1e336fe1b2d746028d65d22a3c6b")
        XCTAssertEqual(val.oAuthKeyData!.Y, "8325432b3a3418d632b4fe93db094d6d83250eea60fe512897c0ad548737f8a5")
        XCTAssertEqual(val.finalKeyData!.evmAddress, "0x462A8BF111A55C9354425F875F89B22678c0Bc44")
        XCTAssertEqual(val.finalKeyData!.X, "36e257717f746cdd52ba85f24f7c9040db8977d3b0354de70ed43689d24fa1b1")
        XCTAssertEqual(val.finalKeyData!.Y, "58ec9768c2fe871b3e2a83cdbcf37ba6a88ad19ec2f6e16a66231732713fd507")
        XCTAssertEqual(val.metadata?.pubNonce?.x, "5d03a0df9b3db067d3363733df134598d42873bb4730298a53ee100975d703cc")
        XCTAssertEqual(val.metadata?.pubNonce?.y, "279434dcf0ff22f077877a70bcad1732412f853c96f02505547f7ca002b133ed")
        XCTAssertEqual(val.metadata?.nonce, BigUInt.zero)
        XCTAssertEqual(val.metadata?.upgraded, false)
        XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
    }

    func testKeepPublicAddressSame() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

        let publicAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
        let publicAddress2 = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

        XCTAssertEqual(publicAddress.finalKeyData?.evmAddress, publicAddress2.finalKeyData?.evmAddress)
        XCTAssertNotEqual(publicAddress.finalKeyData?.evmAddress, nil)
        XCTAssertNotEqual(publicAddress2.finalKeyData?.evmAddress, "")
    }

    func testFetchPublicAddressAndUserType() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

        let result = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

        XCTAssertEqual(result.finalKeyData?.evmAddress.lowercased(), "0x462a8bf111a55c9354425f875f89b22678c0bc44".lowercased())

        XCTAssertEqual(result.metadata?.typeOfUser, .v2)

        XCTAssertEqual(result.metadata?.pubNonce?.x, "5d03a0df9b3db067d3363733df134598d42873bb4730298a53ee100975d703cc")

        XCTAssertEqual(result.metadata?.pubNonce?.y, "279434dcf0ff22f077877a70bcad1732412f853c96f02505547f7ca002b133ed")
    }

    func testKeyAssignSapphireDevnet() async throws {
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = fakeEmail
        let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
        let data = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
        XCTAssertNotNil(data.finalKeyData)
        XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
        XCTAssertEqual(data.metadata?.typeOfUser, .v2)
    }

    func testAbleToLogin() async throws {
        let token = try generateIdToken(email: TORUS_TEST_EMAIL)

        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)

        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

        let data = try await torus.retrieveShares(
            endpoints: nodeDetails.getTorusNodeEndpoints(),
            torusNodePubs: nodeDetails.getTorusNodePub(),
            indexes: nodeDetails.getTorusIndexes(),
            verifier: TORUS_TEST_VERIFIER,
            verifierParams: verifierParams,
            idToken: token
        )

        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x462A8BF111A55C9354425F875F89B22678c0Bc44")
        XCTAssertEqual(data.finalKeyData?.X, "36e257717f746cdd52ba85f24f7c9040db8977d3b0354de70ed43689d24fa1b1")
        XCTAssertEqual(data.finalKeyData?.Y, "58ec9768c2fe871b3e2a83cdbcf37ba6a88ad19ec2f6e16a66231732713fd507")
        XCTAssertEqual(data.finalKeyData?.privKey, "230dad9f42039569e891e6b066ff5258b14e9764ef5176d74aeb594d1a744203")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x137B3607958562D03Eb3C6086392D1eFa01aA6aa")
        XCTAssertEqual(data.oAuthKeyData?.X, "118a674da0c68f16a1123de9611ba655f4db1e336fe1b2d746028d65d22a3c6b")
        XCTAssertEqual(data.oAuthKeyData?.Y, "8325432b3a3418d632b4fe93db094d6d83250eea60fe512897c0ad548737f8a5")
        XCTAssertEqual(data.oAuthKeyData?.privKey, "6b3c872a269aa8994a5acc8cdd70ea3d8d182d42f8af421c0c39ea124e9b66fa")
        XCTAssertNotEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertNotEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(data.metadata?.pubNonce?.x, "5d03a0df9b3db067d3363733df134598d42873bb4730298a53ee100975d703cc")
        XCTAssertEqual(data.metadata?.pubNonce?.y, "279434dcf0ff22f077877a70bcad1732412f853c96f02505547f7ca002b133ed")
        XCTAssertEqual(data.metadata?.nonce?.serialize().toHexString(), "b7d126751b68ecd09e371a23898e6819dee54708a5ead4f6fe83cdc79c0f1c4a")
        XCTAssertEqual(data.metadata?.typeOfUser, .v2)
        XCTAssertEqual(data.metadata?.upgraded, false)
    }

    func testNewUserLogin() async throws {
        let fakeEmail = generateRandomEmail(of: 6)
        let verifierId = fakeEmail // faker random address
        let token = try generateIdToken(email: verifierId)

        let verifierParams = VerifierParams(verifier_id: verifierId)

        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: verifierId)

        let data = try await torus.retrieveShares(
            endpoints: nodeDetails.getTorusNodeEndpoints(),
            torusNodePubs: nodeDetails.getTorusNodePub(),
            indexes: nodeDetails.getTorusIndexes(),
            verifier: TORUS_TEST_VERIFIER,
            verifierParams: verifierParams,
            idToken: token
        )

        XCTAssertEqual(data.metadata?.typeOfUser, .v2)
        XCTAssertEqual(data.metadata?.upgraded, false)
        XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
        XCTAssertNotEqual(data.finalKeyData?.X, "")
        XCTAssertNotEqual(data.finalKeyData?.Y, "")
        XCTAssertNotEqual(data.finalKeyData?.privKey, "")
        XCTAssertNotEqual(data.oAuthKeyData?.evmAddress, "")
        XCTAssertNotEqual(data.oAuthKeyData?.X, "")
        XCTAssertNotEqual(data.oAuthKeyData?.Y, "")
        XCTAssertNotEqual(data.oAuthKeyData?.privKey, "")
        XCTAssertNotEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertNotEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertNotEqual(data.metadata?.pubNonce?.x, "")
        XCTAssertNotEqual(data.metadata?.pubNonce?.y, "")
    }

    func testNodeDownAbleToLogin() async throws {
        let token = try generateIdToken(email: TORUS_TEST_EMAIL)

        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

        var torusNodeEndpoints = nodeDetails.getTorusNodeSSSEndpoints()
        torusNodeEndpoints[1] = "https://example.com"

        let data = try await torus.retrieveShares(endpoints: torusNodeEndpoints,
                                                  torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(),
                                                  verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)

        XCTAssertEqual(data.finalKeyData?.evmAddress, "0x462A8BF111A55C9354425F875F89B22678c0Bc44")
        XCTAssertEqual(data.finalKeyData?.X, "36e257717f746cdd52ba85f24f7c9040db8977d3b0354de70ed43689d24fa1b1")
        XCTAssertEqual(data.finalKeyData?.Y, "58ec9768c2fe871b3e2a83cdbcf37ba6a88ad19ec2f6e16a66231732713fd507")
        XCTAssertEqual(data.finalKeyData?.privKey, "230dad9f42039569e891e6b066ff5258b14e9764ef5176d74aeb594d1a744203")
        XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0x137B3607958562D03Eb3C6086392D1eFa01aA6aa")
        XCTAssertEqual(data.oAuthKeyData?.X, "118a674da0c68f16a1123de9611ba655f4db1e336fe1b2d746028d65d22a3c6b")
        XCTAssertEqual(data.oAuthKeyData?.Y, "8325432b3a3418d632b4fe93db094d6d83250eea60fe512897c0ad548737f8a5")
        XCTAssertEqual(data.oAuthKeyData?.privKey, "6b3c872a269aa8994a5acc8cdd70ea3d8d182d42f8af421c0c39ea124e9b66fa")
        XCTAssertNotEqual(data.sessionData?.sessionTokenData.count, 0)
        XCTAssertNotEqual(data.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(data.metadata?.pubNonce?.x, "5d03a0df9b3db067d3363733df134598d42873bb4730298a53ee100975d703cc")
        XCTAssertEqual(data.metadata?.pubNonce?.y, "279434dcf0ff22f077877a70bcad1732412f853c96f02505547f7ca002b133ed")
        XCTAssertEqual(data.metadata?.nonce?.serialize().toHexString(), "b7d126751b68ecd09e371a23898e6819dee54708a5ead4f6fe83cdc79c0f1c4a")
        XCTAssertEqual(data.metadata?.typeOfUser, .v2)
        XCTAssertEqual(data.metadata?.upgraded, false)
    }

    func testPubAdderessOfTssVerifierId() async throws {
        let email = TORUS_EXTENDED_VERIFIER_EMAIL
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: email)

        let pubAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, extendedVerifierId: tssVerifierId)

        XCTAssertEqual(pubAddress.oAuthKeyData!.evmAddress, "0xBd6Bc8aDC5f2A0526078Fd2016C4335f64eD3a30")
        XCTAssertEqual(pubAddress.oAuthKeyData!.X, "d45d4ad45ec643f9eccd9090c0a2c753b1c991e361388e769c0dfa90c210348c")
        XCTAssertEqual(pubAddress.oAuthKeyData!.Y, "fdc151b136aa7df94e97cc7d7007e2b45873c4b0656147ec70aad46e178bce1e")
        XCTAssertEqual(pubAddress.finalKeyData!.evmAddress, "0xBd6Bc8aDC5f2A0526078Fd2016C4335f64eD3a30")
        XCTAssertEqual(pubAddress.finalKeyData!.X, "d45d4ad45ec643f9eccd9090c0a2c753b1c991e361388e769c0dfa90c210348c")
        XCTAssertEqual(pubAddress.finalKeyData!.Y, "fdc151b136aa7df94e97cc7d7007e2b45873c4b0656147ec70aad46e178bce1e")
        XCTAssertEqual(pubAddress.metadata?.pubNonce?.x, nil)
        XCTAssertEqual(pubAddress.metadata?.pubNonce?.y, nil)
        XCTAssertEqual(pubAddress.metadata?.nonce, BigUInt("0"))
        XCTAssertEqual(pubAddress.metadata?.upgraded, false)
        XCTAssertEqual(pubAddress.metadata?.typeOfUser, UserType(rawValue: "v2"))
    }

    func testAssignKeyToTssVerifier() async throws {
        let fakeEmail = generateRandomEmail(of: 6)
        let verifierId = fakeEmail // faker random address
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(verifierId)\u{0015}\(tssTag)\u{0016}\(nonce)"

        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: verifierId)
        let keyData = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: TORUS_TEST_VERIFIER, verifierId: verifierId, extendedVerifierId: tssVerifierId)
        XCTAssertNotEqual(keyData.finalKeyData?.evmAddress, nil)
        XCTAssertNotEqual(keyData.finalKeyData?.evmAddress, "")
        XCTAssertEqual(keyData.metadata?.typeOfUser, .v2)
        XCTAssertEqual(keyData.metadata?.nonce, BigUInt("0"))
        XCTAssertEqual(keyData.metadata?.upgraded, false)
    }

    func testAllowTssVerifierIdFetchShare() async throws {
        let email = generateRandomEmail(of: 6) // faker random address ???
        let verifierId = TORUS_TEST_EMAIL
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"

        let token = try generateIdToken(email: email)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: verifierId)
        let verifierParams = VerifierParams(verifier_id: verifierId, extended_verifier_id: tssVerifierId)

        let result = try await torus.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(),
                                                    torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(),
                                                    verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)

        XCTAssertNotEqual(result.finalKeyData?.privKey, nil)
        XCTAssertNotEqual(result.finalKeyData?.evmAddress, nil)
        XCTAssertEqual(result.metadata?.typeOfUser, .v2)
        XCTAssertEqual(result.metadata?.nonce, BigUInt("0"))
        XCTAssertEqual(result.metadata?.upgraded, true)
    }

    func testFetchPubAdderessWhenHashEnabled() async throws {
        let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: HashEnabledVerifier)
        let pubAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(),
                                                          torusNodePubs: nodeDetails.getTorusNodePub(),
                                                          verifier: HashEnabledVerifier, verifierId: TORUS_HASH_ENABLED_TEST_EMAIL)
        XCTAssertEqual(pubAddress.oAuthKeyData!.evmAddress, "0x4135ad20D2E9ACF37D64E7A6bD8AC34170d51219")
        XCTAssertEqual(pubAddress.oAuthKeyData!.X, "9c591943683c0e5675f99626cea84153a3c5b72c6e7840f8b8b53d0f2bb50c67")
        XCTAssertEqual(pubAddress.oAuthKeyData!.Y, "9d9896d82e565a2d5d437745af6e4560f3564c2ac0d0edcb72e0b508b3ac05a0")
        XCTAssertEqual(pubAddress.finalKeyData!.evmAddress, "0xF79b5ffA48463eba839ee9C97D61c6063a96DA03")
        XCTAssertEqual(pubAddress.finalKeyData!.X, "21cd0ae3168d60402edb8bd65c58ff4b3e0217127d5bb5214f03f84a76f24d8a")
        XCTAssertEqual(pubAddress.finalKeyData!.Y, "575b7a4d0ef9921b3b1b84f30d412e87bc69b4eab83f6706e247cceb9e985a1e")
        XCTAssertEqual(pubAddress.metadata?.pubNonce?.x, "d6404befc44e3ab77a8387829d77e9c77a9c2fb37ae314c3a59bdc108d70349d")
        XCTAssertEqual(pubAddress.metadata?.pubNonce?.y, "1054dfe297f1d977ccc436109cbcce64e95b27f93efc0f1dab739c9146eda2e")
        XCTAssertEqual(pubAddress.metadata?.nonce, BigUInt.zero)
        XCTAssertEqual(pubAddress.metadata?.upgraded, false)
        XCTAssertEqual(pubAddress.metadata?.typeOfUser, UserType(rawValue: "v2"))
    }

    func testLoginWhenHashEnabled() async throws {
        let email = TORUS_TEST_EMAIL
        let token = try generateIdToken(email: email)
        let verifierParams = VerifierParams(verifier_id: email)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: HashEnabledVerifier, veriferID: HashEnabledVerifier)
        let result = try await torus.retrieveShares(endpoints: nodeDetails.getTorusNodeSSSEndpoints(),
                                                    torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(),
                                                    verifier: HashEnabledVerifier, verifierParams: verifierParams, idToken: token)
        XCTAssertEqual(result.finalKeyData?.evmAddress, "0x8a7e297e20804786767B1918a5CFa11683e5a3BB")
        XCTAssertEqual(result.finalKeyData?.X, "7927d5281aea24fd93f41696f79c91370ec0097ff65e83e95691fffbde6d733a")
        XCTAssertEqual(result.finalKeyData?.Y, "f22735f0e72ff225274cf499d50b240b7571063e0584471b2b4dab337ad5d8da")
        XCTAssertEqual(result.finalKeyData?.privKey, "f161f63a84f1c935525ec0bda74bc5a15de6a9a7be28fad237ef6162df335fe6")
        XCTAssertEqual(result.oAuthKeyData?.evmAddress, "0xaEafa3Fc7349E897F8fCe981f55bbD249f12aC8C")
        XCTAssertEqual(result.oAuthKeyData?.X, "72d9172d7edc623266d6c625db91505e6b64a5524e6d7c7c0184b1bbdea1e986")
        XCTAssertEqual(result.oAuthKeyData?.Y, "8c26d557a0a9cb22dc2a30d36bf67de93a0eb6d4ef503a849c7de2d14dcbdaaa")
        XCTAssertEqual(result.oAuthKeyData?.privKey, "62e110d9d698979c1966d14b2759006cf13be7dfc86a63ff30812e2032163f2f")
        XCTAssertNotEqual(result.sessionData?.sessionTokenData.count, 0)
        XCTAssertNotEqual(result.sessionData?.sessionAuthKey, "")
        XCTAssertEqual(result.metadata?.pubNonce?.x, "5712d789f7ecf3435dd9bf1136c2daaa634f0222d64e289d2abe30a729a6a22b")
        XCTAssertEqual(result.metadata?.pubNonce?.y, "2d2b4586fd5fd9d15c22f66b61bc475742754a8b96d1edb7b2590e4c4f97b3f0")
        XCTAssertEqual(result.metadata?.nonce?.serialize().toHexString(), "8e80e560ae59319938f7ef727ff2c5346caac1c7f5be96d3076e3342ad1d20b7")
        XCTAssertEqual(result.metadata?.typeOfUser, .v2)
        XCTAssertEqual(result.metadata?.upgraded, false)
    }

    func testAggregrateLoginWithEmail(email: String) async throws {
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = email
        let jwt = try! generateIdToken(email: email)
        let hashedIDToken = keccak256Data(jwt.data(using: .utf8) ?? Data()).toHexString()
        let extraParams = ["verifier_id": email, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": email, "idtoken": jwt]]] as [String: Codable]

        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let endpoint = try await nodeManager.getNodeDetails(verifier: HashEnabledVerifier, verifierID: verifierID)

        let verifierParams = VerifierParams(verifier_id: verifierID)
        let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)

        let data = try await torus.retrieveShares(endpoints: endpoint.torusNodeEndpoints, torusNodePubs: nodeDetails.getTorusNodePub(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)

        XCTAssertNotNil(data.finalKeyData?.evmAddress)
        XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
        XCTAssertNotNil(data.oAuthKeyData?.evmAddress)
        XCTAssertEqual(data.metadata?.typeOfUser == UserType.v2, true)
        XCTAssertNotNil(data.metadata?.nonce)
        XCTAssertEqual(data.metadata?.upgraded, false)
    }

    func testAggregateLoginWithFixedEmail() async throws {
        // This fixed email was previously known to trigger an edge case that
        // revealed a bug in our share decryption implementation.
        let email = "hEJTRg@gmail.com"
        try await testAggregrateLoginWithEmail(email: email)
    }

    /* TODO: Investigate further
    func testAggregateLoginWithRandomEmail() async throws {
        let email = generateRandomEmail(of: 6)
        try await testAggregrateLoginWithEmail(email: email)
    }
    */
    
    
    func testGating() async throws {
        let torus = TorusUtils(enableOneKey: true, network: .sapphire(.SAPPHIRE_MAINNET), clientId: "YOUR_CLIENT_ID")
        let token = try generateIdToken(email: TORUS_TEST_EMAIL)

        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)

        let nodeDetails = try await get_fnd_and_tu_data(verifer: "w3a-auth0-demo", veriferID: TORUS_TEST_EMAIL)

        do {
            _ = try await torus.retrieveShares(
                endpoints: nodeDetails.getTorusNodeEndpoints(),
                torusNodePubs: nodeDetails.getTorusNodePub(),
                indexes: nodeDetails.getTorusIndexes(),
                verifier: "w3a-auth0-demo",
                verifierParams: verifierParams,
                idToken: token
            )
            XCTAssert(false, "Should not pass")
        }catch {
            if (!error.localizedDescription.contains("code: 1001")) {
                XCTAssert(false, "Should fail with signer allow gating error")
            }
        }

    }
    
    func testencryption() async throws {
        let torus = TorusUtils(enableOneKey: true, network: .sapphire(.SAPPHIRE_MAINNET), clientId: "YOUR_CLIENT_ID")

        let pk = curveSecp256k1.SecretKey()
        let pk_str = try pk.serialize()
        
        let msg = "hello test data"
        let encryptData = try torus.encrypt(publicKey: pk.toPublic().serialize(compressed: false), msg: msg)
        
        let curveMsg = try Encryption.encrypt(pk: pk.toPublic(), plainText: msg.data(using: .utf8)!)
        let em = try EncryptedMessage(cipherText: encryptData.ciphertext, ephemeralPublicKey: PublicKey(hex: encryptData.ephemPublicKey) , iv: encryptData.iv, mac: encryptData.mac)

        let eciesData = ECIES(iv: encryptData.iv, ephemPublicKey: encryptData.ephemPublicKey, ciphertext: encryptData.ciphertext, mac: encryptData.mac)
        let emp = try curveMsg.ephemeralPublicKey().serialize(compressed: false);
        let eciesData2 = try ECIES(iv: curveMsg.iv(), ephemPublicKey: emp, ciphertext: curveMsg.chipherText(), mac: curveMsg.mac())
        
        let decrypteData = try torus.decrypt(privateKey: pk_str, opts: eciesData)
        let decrypteData2 = try torus.decrypt(privateKey: pk_str, opts: eciesData2)
        
        let result = try Encryption.decrypt(sk: pk, encrypted: em)
        let result2 = try Encryption.decrypt(sk: pk, encrypted: curveMsg)
        
        XCTAssertEqual(msg.data(using: .utf8)!, result)
        XCTAssertEqual(msg.data(using: .utf8)!, result2)
        
    }

}
