import BigInt
import FetchNodeDetails
import JWTKit
import secp256k1
import web3
import XCTest

import CommonSources

@testable import TorusUtils

@available(iOS 13.0, *)
final class SapphireTest: XCTestCase {

    static var fetchNodeDetails: AllNodeDetailsModel?
    // static var nodeDetails: NodeDetails?
    static var utils: TorusUtils?
    static var endpoints: [String] = []
    static var nodePubKeys: [TorusNodePubModel] = []
    static var privKey: String = ""

    let TORUS_TEST_VERIFIER = "torus-test-health"
    let TORUS_TEST_AGGREGATE_VERIFIER = "torus-test-health-aggregate"
    let TORUS_TEST_EMAIL = "saasas@tr.us"
    let TORUS_IMPORT_EMAIL = "importeduser5@tor.us"
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
        torus = TorusUtils(enableOneKey: enableOneKey, network: .sapphire(.SAPPHIRE_DEVNET))
        return nodeDetails
    }
    
    func testFetchPublicAddress() async throws {
        let exp1 = XCTestExpectation(description: "Should be able to fetch public address")

        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

            let val = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.torusNodePub, verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
            XCTAssertEqual(val.oAuthKeyData!.evmAddress, "0xac997dE675Fb69FCb0F4115A23c0061A892A2772")
            XCTAssertEqual(val.oAuthKeyData!.X, "9508a251dfc4146a132feb96111c136538f4fabd20fc488dbcaaf762261c1528")
            XCTAssertEqual(val.oAuthKeyData!.Y, "f9128bc7403bab6d45415cad01dd0ba0924628cfb6bf51c17e77aa8ca43b3cfe")
            XCTAssertEqual(val.finalKeyData!.evmAddress, "0x4924F91F5d6701dDd41042D94832bB17B76F316F")
            XCTAssertEqual(val.finalKeyData!.X, "f3eaf63bf1fd645d4159832ccaad7f42457e287ac929363ba636eb7e87978bff")
            XCTAssertEqual(val.finalKeyData!.Y, "f3b9d8dd91927a89ec45199ad697fe3fa01b8b836710143a0babb1a4eb35f1cd")
            XCTAssertEqual(val.metadata?.pubNonce?.x, "78a88b99d960808543e75076529c913c1678bc7fafbb943f1ce58235fd2f4e0c")
            XCTAssertEqual(val.metadata?.pubNonce?.y, "6b451282135dfacd22561e0fb5bf21aea7b1f26f2442164b82b0e4c8f152f7a7")
            XCTAssertEqual(val.metadata?.nonce, BigUInt("376df8a62e2e72a2b3e87e97c85f86b3f2dac41082ddeb863838d80462deab5e", radix: 16))
            XCTAssertEqual(val.metadata?.upgraded, false)
            XCTAssertEqual(val.metadata?.typeOfUser, UserType(rawValue: "v2"))
            XCTAssertEqual(val.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        
    }
    
    func testKeepPublicAddressSame() async throws {
        let exp1 = XCTestExpectation(description: "should keep public address same")
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

            let publicAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)
            let publicAddress2 = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

            XCTAssertEqual(publicAddress.finalKeyData?.evmAddress, publicAddress2.finalKeyData?.evmAddress)
            XCTAssertNotEqual(publicAddress.finalKeyData?.evmAddress, nil)
            XCTAssertNotEqual(publicAddress2.finalKeyData?.evmAddress, "")
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }

    }
    
    func testFetchPublicAddressAndUserType() async throws {
        
        let exp1 = XCTestExpectation(description: "should fetch user type and public address")
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

            let result = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL)

            XCTAssertEqual(result.finalKeyData?.evmAddress.lowercased(), "0x4924F91F5d6701dDd41042D94832bB17B76F316F".lowercased())
            
            XCTAssertEqual(result.metadata?.typeOfUser, .v2)
            
            XCTAssertEqual(result.metadata?.pubNonce?.x, "78a88b99d960808543e75076529c913c1678bc7fafbb943f1ce58235fd2f4e0c")
            
            XCTAssertEqual(result.metadata?.pubNonce?.y, "6b451282135dfacd22561e0fb5bf21aea7b1f26f2442164b82b0e4c8f152f7a7")
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
        
    }

    func testKeyAssignSapphireDevnet() async {
        let exp1 = XCTestExpectation(description: "should be able to key assign")
        let fakeEmail = generateRandomEmail(of: 6)
        let verifier: String = TORUS_TEST_VERIFIER
        let verifierID: String = fakeEmail
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
            let data = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifier, verifierId: verifierID)
            XCTAssertNotNil(data.finalKeyData)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            XCTAssertEqual(data.metadata?.typeOfUser, .v2)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
    func testAbleToLogin() async throws {
        let exp1 = XCTestExpectation(description: "Should be able to do a Login")

        let token = try generateIdToken(email: TORUS_TEST_EMAIL)

        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)

            let data = try await torus.retrieveShares(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)
            
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x4924F91F5d6701dDd41042D94832bB17B76F316F")
            XCTAssertEqual(data.finalKeyData?.X, "f3eaf63bf1fd645d4159832ccaad7f42457e287ac929363ba636eb7e87978bff")
            XCTAssertEqual(data.finalKeyData?.Y, "f3b9d8dd91927a89ec45199ad697fe3fa01b8b836710143a0babb1a4eb35f1cd")
            XCTAssertEqual(data.finalKeyData?.privKey, "04eb166ddcf59275a210c7289dca4a026f87a33fd2d6ed22f56efae7eab4052c")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0xac997dE675Fb69FCb0F4115A23c0061A892A2772")
            XCTAssertEqual(data.oAuthKeyData?.X, "9508a251dfc4146a132feb96111c136538f4fabd20fc488dbcaaf762261c1528")
            XCTAssertEqual(data.oAuthKeyData?.Y, "f9128bc7403bab6d45415cad01dd0ba0924628cfb6bf51c17e77aa8ca43b3cfe")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "cd7d1dc7aec71fd2ee284890d56ac34d375bbc15ff41a1d87d088170580b9b0f")
            XCTAssertNotEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertNotEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce?.x, "78a88b99d960808543e75076529c913c1678bc7fafbb943f1ce58235fd2f4e0c")
            XCTAssertEqual(data.metadata?.pubNonce?.y, "6b451282135dfacd22561e0fb5bf21aea7b1f26f2442164b82b0e4c8f152f7a7")
            XCTAssertEqual(data.metadata?.nonce, BigUInt(hex: "376df8a62e2e72a2b3e87e97c85f86b3f2dac41082ddeb863838d80462deab5e"))
            XCTAssertEqual(data.metadata?.typeOfUser, .v2)
            XCTAssertEqual(data.metadata?.upgraded, false)
            XCTAssertNotEqual(data.nodesData?.nodeIndexes.count, 0)

            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }

        
    }
    
    func testNodeDownAbleToLogin () async throws {
        let exp1 = XCTestExpectation(description: "should be able to login even when node is down")

        let token = try generateIdToken(email: TORUS_TEST_EMAIL)

        let verifierParams = VerifierParams(verifier_id: TORUS_TEST_EMAIL)
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: TORUS_TEST_EMAIL)
            
            var torusNodeEndpoints = nodeDetails.getTorusNodeSSSEndpoints()
            torusNodeEndpoints[1] = "https://example.com"

            let data = try await torus.retrieveShares(endpoints: torusNodeEndpoints, verifier: TORUS_TEST_VERIFIER, verifierParams: verifierParams, idToken: token)
            
            XCTAssertEqual(data.finalKeyData?.evmAddress, "0x4924F91F5d6701dDd41042D94832bB17B76F316F")
            XCTAssertEqual(data.finalKeyData?.X, "f3eaf63bf1fd645d4159832ccaad7f42457e287ac929363ba636eb7e87978bff")
            XCTAssertEqual(data.finalKeyData?.Y, "f3b9d8dd91927a89ec45199ad697fe3fa01b8b836710143a0babb1a4eb35f1cd")
            XCTAssertEqual(data.finalKeyData?.privKey, "04eb166ddcf59275a210c7289dca4a026f87a33fd2d6ed22f56efae7eab4052c")
            XCTAssertEqual(data.oAuthKeyData?.evmAddress, "0xac997dE675Fb69FCb0F4115A23c0061A892A2772")
            XCTAssertEqual(data.oAuthKeyData?.X, "9508a251dfc4146a132feb96111c136538f4fabd20fc488dbcaaf762261c1528")
            XCTAssertEqual(data.oAuthKeyData?.Y, "f9128bc7403bab6d45415cad01dd0ba0924628cfb6bf51c17e77aa8ca43b3cfe")
            XCTAssertEqual(data.oAuthKeyData?.privKey, "cd7d1dc7aec71fd2ee284890d56ac34d375bbc15ff41a1d87d088170580b9b0f")
            XCTAssertNotEqual(data.sessionData?.sessionTokenData.count, 0)
            XCTAssertNotEqual(data.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(data.metadata?.pubNonce?.x, "78a88b99d960808543e75076529c913c1678bc7fafbb943f1ce58235fd2f4e0c")
            XCTAssertEqual(data.metadata?.pubNonce?.y, "6b451282135dfacd22561e0fb5bf21aea7b1f26f2442164b82b0e4c8f152f7a7")
            XCTAssertEqual(data.metadata?.nonce, BigUInt(hex: "376df8a62e2e72a2b3e87e97c85f86b3f2dac41082ddeb863838d80462deab5e"))
            XCTAssertEqual(data.metadata?.typeOfUser, .v2)
            XCTAssertEqual(data.metadata?.upgraded, false)
            XCTAssertNotEqual(data.nodesData?.nodeIndexes.count, 0)

            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }

    func testPubAdderessOfTssVerifierId() async throws {
        let email = TORUS_EXTENDED_VERIFIER_EMAIL
        let exp1 = XCTestExpectation(description: "should fetch pub address of tss verifier id")
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: email)
            
            let pubAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: TORUS_TEST_EMAIL, extendedVerifierId: tssVerifierId)
            
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
            XCTAssertEqual(pubAddress.nodesData?.nodeIndexes.count, 0)

            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
        
    }
    
    func testAssignKeyToTssVerifier() async throws {
        
        let exp1 = XCTestExpectation(description: "should assign key to tss verifier id")
        
        // fixme
        let email = "faker@gmail.com" //faker random address
        let verifierId = TORUS_TEST_EMAIL //faker random address
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: verifierId)
            let publicAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), verifier: TORUS_TEST_VERIFIER, verifierId: verifierId)
            XCTAssertNotEqual(publicAddress.finalKeyData?.evmAddress, nil)
            XCTAssertNotEqual(publicAddress.finalKeyData?.evmAddress, "")
            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }

    }
    
    func testAllowTssVerifierIdFetchShare () async throws {
        
        let email = TORUS_TEST_EMAIL //faker random address ???
        let verifierId = TORUS_TEST_EMAIL
        let nonce = 0
        let tssTag = "default"
        let tssVerifierId = "\(email)\u{0015}\(tssTag)\u{0016}\(nonce)"
        
        let token = try generateIdToken(email: email)
        let nodeManager = NodeDetailManager(network: TorusNetwork.sapphire(.SAPPHIRE_DEVNET))
        let endpoint = try await nodeManager.getNodeDetails(verifier: TORUS_TEST_VERIFIER, verifierID: verifierId)
        let verifierParams = VerifierParams(verifier_id: verifierId, extended_verifier_id: tssVerifierId)
        
        try await torus?.retrieveShares(endpoints: endpoint.torusNodeSSSEndpoints, verifier: TORUS_TEST_EMAIL, verifierParams: verifierParams, idToken: token)
    }

    
    func testFetchPubAdderessWhenHashEnabled () async throws {
        
        let exp1 = XCTestExpectation(description: "should fetch public address when verifierID hash enabled")

        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: TORUS_TEST_VERIFIER, veriferID: HashEnabledVerifier)
            let pubAddress = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), verifier: HashEnabledVerifier, verifierId: TORUS_TEST_EMAIL)
            XCTAssertEqual(pubAddress.oAuthKeyData!.evmAddress, "0x4135ad20D2E9ACF37D64E7A6bD8AC34170d51219")
            XCTAssertEqual(pubAddress.oAuthKeyData!.X, "9c591943683c0e5675f99626cea84153a3c5b72c6e7840f8b8b53d0f2bb50c67")
            XCTAssertEqual(pubAddress.oAuthKeyData!.Y, "9d9896d82e565a2d5d437745af6e4560f3564c2ac0d0edcb72e0b508b3ac05a0")
            XCTAssertEqual(pubAddress.finalKeyData!.evmAddress, "0xF79b5ffA48463eba839ee9C97D61c6063a96DA03")
            XCTAssertEqual(pubAddress.finalKeyData!.X, "21cd0ae3168d60402edb8bd65c58ff4b3e0217127d5bb5214f03f84a76f24d8a")
            XCTAssertEqual(pubAddress.finalKeyData!.Y, "575b7a4d0ef9921b3b1b84f30d412e87bc69b4eab83f6706e247cceb9e985a1e")
            XCTAssertEqual(pubAddress.metadata?.pubNonce?.x, "d6404befc44e3ab77a8387829d77e9c77a9c2fb37ae314c3a59bdc108d70349d")
            XCTAssertEqual(pubAddress.metadata?.pubNonce?.y, "1054dfe297f1d977ccc436109cbcce64e95b27f93efc0f1dab739c9146eda2e")
            XCTAssertEqual(pubAddress.metadata?.nonce, BigUInt("51eb06f7901d5a8562274d3e53437328ca41ad96926f075122f6bd50e31be52d", radix: 16))
            XCTAssertEqual(pubAddress.metadata?.upgraded, false)
            XCTAssertEqual(pubAddress.metadata?.typeOfUser, UserType(rawValue: "v2"))
            XCTAssertNotEqual(pubAddress.nodesData?.nodeIndexes.count, 0)

            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }

    }

    func testLoginWhenHashEnabled () async throws {
        
        let exp1 = XCTestExpectation(description: "should be able to login when verifierID hash enabled")
        let email = TORUS_TEST_EMAIL
        let token = try generateIdToken(email: email)
        let verifierParams = VerifierParams(verifier_id: email )
        
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: HashEnabledVerifier, veriferID: HashEnabledVerifier)
            let result = try await torus.retrieveShares(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), verifier: HashEnabledVerifier, verifierParams: verifierParams, idToken: token )
            XCTAssertEqual(result.finalKeyData?.evmAddress, "0xF79b5ffA48463eba839ee9C97D61c6063a96DA03")
            XCTAssertEqual(result.finalKeyData?.X, "21cd0ae3168d60402edb8bd65c58ff4b3e0217127d5bb5214f03f84a76f24d8a")
            XCTAssertEqual(result.finalKeyData?.Y, "575b7a4d0ef9921b3b1b84f30d412e87bc69b4eab83f6706e247cceb9e985a1e")
            XCTAssertEqual(result.finalKeyData?.privKey, "066270dfa345d3d0415c8223e045f366b238b50870de7e9658e3c6608a7e2d32")
            XCTAssertEqual(result.oAuthKeyData?.evmAddress, "0x4135ad20D2E9ACF37D64E7A6bD8AC34170d51219")
            XCTAssertEqual(result.oAuthKeyData?.X, "9c591943683c0e5675f99626cea84153a3c5b72c6e7840f8b8b53d0f2bb50c67")
            XCTAssertEqual(result.oAuthKeyData?.Y, "9d9896d82e565a2d5d437745af6e4560f3564c2ac0d0edcb72e0b508b3ac05a0")
            XCTAssertEqual(result.oAuthKeyData?.privKey, "b47769e81328794adf3534e58d02803ca2a5e4588db81780f5bf679c77988946")
            XCTAssertEqual(result.sessionData?.sessionTokenData.count, 0)
            XCTAssertEqual(result.sessionData?.sessionAuthKey, "")
            XCTAssertEqual(result.metadata?.pubNonce?.x, "d6404befc44e3ab77a8387829d77e9c77a9c2fb37ae314c3a59bdc108d70349d")
            XCTAssertEqual(result.metadata?.pubNonce?.y, "1054dfe297f1d977ccc436109cbcce64e95b27f93efc0f1dab739c9146eda2e")
            XCTAssertEqual(result.metadata?.nonce, BigUInt(hex: "51eb06f7901d5a8562274d3e53437328ca41ad96926f075122f6bd50e31be52d"))
            XCTAssertEqual(result.metadata?.typeOfUser, .v2)
            XCTAssertEqual(result.metadata?.upgraded, false)
            XCTAssertEqual(result.nodesData?.nodeIndexes.count, 0)
            exp1.fulfill()
        } catch let error{
            XCTFail(error.localizedDescription)
            exp1.fulfill()
        }
    }
    
    func testAggregrateLogin() async throws {
        let exp1 = XCTestExpectation(description: "Should be able to aggregate login")
        let email = TORUS_TEST_EMAIL
        let verifier: String = TORUS_TEST_AGGREGATE_VERIFIER
        let verifierID: String = email
        let jwt = try! generateIdToken(email: email)
        let hashedIDToken = jwt.sha3(.keccak256)
        let extraParams = ["verifier_id": email, "sub_verifier_ids": [TORUS_TEST_VERIFIER], "verify_params": [["verifier_id": email, "idtoken": jwt]]] as [String: Codable]

        let nodeManager = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))
        let endpoint = try await nodeManager.getNodeDetails(verifier: HashEnabledVerifier, verifierID: verifierID)

        let verifierParams = VerifierParams(verifier_id: verifierID)
        do {
            let nodeDetails = try await get_fnd_and_tu_data(verifer: verifier, veriferID: verifierID)
            
            let data = try await torus.retrieveShares(endpoints: endpoint.torusNodeEndpoints, torusNodePubs: nodeDetails.torusNodePub, verifier: verifier, verifierParams: verifierParams, idToken: hashedIDToken, extraParams: extraParams)
            
            XCTAssertNotNil(data.finalKeyData?.evmAddress)
            XCTAssertNotEqual(data.finalKeyData?.evmAddress, "")
            XCTAssertNotNil(data.oAuthKeyData?.evmAddress)
            XCTAssertEqual(data.metadata?.typeOfUser, .v2)
            XCTAssertNotNil(data.metadata?.nonce)
            XCTAssertEqual(data.metadata?.upgraded, false)
            exp1.fulfill()
        } catch let err {
            XCTFail(err.localizedDescription)
            exp1.fulfill()
        }
    }
    
    
    
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
