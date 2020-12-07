import XCTest
import PromiseKit
import FetchNodeDetails
import CryptoSwift
import BigInt
import web3swift
import secp256k1

/**
 
 cases to test
 - Email provided but wrong token
 - incorrect order of nodes
 - interpolation
 - All functions
 
 */
@testable import TorusUtils

@available(iOS 11.0, *)
final class torus_utils_swiftTests: XCTestCase {
    
    let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    let nodeList = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]
    let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")]
    let verifierId = "shubham@tor.us"
    let verifier = "google-google"
    let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImMxNzcxODE0YmE2YTcwNjkzZmI5NDEyZGEzYzZlOTBjMmJmNWI5MjciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIyMzg5NDE3NDY3MTMtcXFlNGE3cmR1dWsyNTZkOG9pNWwwcTM0cXR1OWdwZmcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIyMzg5NDE3NDY3MTMtcXFlNGE3cmR1dWsyNTZkOG9pNWwwcTM0cXR1OWdwZmcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6IjltMjRLWXhXWVJZbkRxSlphV0NmdVEiLCJub25jZSI6IjEyMyIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQU1adXVjazdCR2hkRkhZdEtfQVN6T01wZlpTSWVHU2NmZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4OTg4NTk0NCwiZXhwIjoxNTg5ODg5NTQ0LCJqdGkiOiI3N2MxMmE3YjM4NzIxNDk3MGVkZmU4ZjE1N2JmZWNlNzk4ODI2MDZiIn0.X7zcizaLeSNA8H1Wli_UIvvS9XRrlKsN42QOgNi4AxUGrQNVfECvFP8TeXeY0iDkZ9rfKCo-M9UTg0DDxPV2epyDD_Y6TphvfKUz-dU5rMYB0i89eYYJNSX5fQZXzn6K_ANe1XSdjvnHWxoYHUdGtzxxb98XqeP4OWGUD23hhwovOhD_d1NXuXEVeckq3FFXpt218lTOllbK2sEKb_bO0U7WNiJTGg983MnYDiWmnAeAB63HKJyZvAGy2gfoCJWCNV2_GqmcNDChHdSqAS8Ypola_HkJTIBZuh5OneOhhGi2CFtMFyQ5h-rsomLcW3Tui5qtzl-yQK_9Gqe2c_vfRw"
    
    let verifyParams = [["GOOGLE_CLIENT_ID": "238941746713-qqe4a7rduuk256d8oi5l0q34qtu9gpfg.apps.googleusercontent.com",
                         "typeOfLogin": "google",
                         "verifier": "google-shubs",]]
    
    override class func setUp() {
        super.setUp()
//        let fnd = FetchNodeDetails()
//        let nodeDetails = fnd.getNodeDetails()
//        let nodeEndpoints = nodeDetails.getTorusNodeEndpoints()
//        let nodePubkeys = nodeDetails.getTorusNodePub()
    }
    
    func testKeyLookup() {
        let obj = TorusUtils()
        
        let exp1 = XCTestExpectation(description: "Do keylookup with success")
        let keyLookupSuccess = obj.keyLookup(endpoints: nodeList, verifier: self.verifier, verifierId: self.verifierId)
        keyLookupSuccess.done { data in
            XCTAssert(data["address"]=="0x5533572d0b2b69Ae31bfDeA351B67B1C05F724Bc", "Address verified")
            exp1.fulfill()
        }.catch{err in
            print(err)
            XCTFail()
            exp1.fulfill()
        }
        
        let exp2 = XCTestExpectation(description: "Do keylookup with failure")
        let keyLookupFailure = obj.keyLookup(endpoints: nodeList, verifier: self.verifier, verifierId: self.verifierId + "someRandomString")
        keyLookupFailure.done { data in
            XCTAssert(data["err"]=="keyLookupfailed", "error verified")
            exp2.fulfill()
        }.catch{err in
            print("keylookup failed", err)
            XCTFail()
            exp2.fulfill()
        }
    
        wait(for: [exp1, exp2], timeout: 5)
    }
    
    func testKeyAssign(){
        let exp1 = XCTestExpectation(description: "Do keyAssign success")
        let obj = TorusUtils(nodePubKeys: nodePubKeys)
        let keyAssign = obj.keyAssign(endpoints: self.nodeList, torusNodePubs: nodePubKeys, verifier: verifier, verifierId: self.verifierId)
        keyAssign.done{ data in
            // print(data)
            XCTAssertNotNil(data)
            exp1.fulfill()
        }.catch{ err in
            print("keyAssign failed", err)
            XCTFail()
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 5)
    }
    
    func testGetPublicAddress(){
        let exp1 = XCTestExpectation(description: "testing get public address")
        let obj = TorusUtils(nodePubKeys: nodePubKeys)
        let getpublicaddress = obj.getPublicAddress(endpoints: self.nodeList, torusNodePubs: nodePubKeys, verifier: "google", verifierId: self.verifierId, isExtended: true)
        getpublicaddress.done{ data in
            print("data", data)
            // Specific to address of shubham@tor.us. Change this to your public address for the above nodelist
            XCTAssert(data["address"]=="0x5533572d0b2b69Ae31bfDeA351B67B1C05F724Bc", "Address verified")
            exp1.fulfill()
        }.catch{ err in
            print("getpublicaddress failed", err)
            XCTFail()
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 10)
    }
    
    func testRetreiveShares(){
        let exp1 = XCTestExpectation(description: "reterive privatekey")
        let obj = TorusUtils(nodePubKeys: nodePubKeys)
        
        let extraParams = ["verifieridentifier": verifier, "verifier_id":verifierId, "sub_verifier_ids":["google-shubs"], "verify_params": [["verifier_id": verifierId, "idtoken": token]]] as [String : Any]
        let extraParams2 = ["verifieridentifier": verifier, "verifier_id":verifierId] as [String : Any]
        
        let dataExample: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams, requiringSecureCoding: false)
        let dataExample2: Data = try! NSKeyedArchiver.archivedData(withRootObject: extraParams2, requiringSecureCoding: false)
        
        
        let key = obj.retrieveShares(endpoints: self.nodeList, verifierIdentifier: verifier,  verifierId: verifierId, idToken: token, extraParams: dataExample2)
        
        key.done{ data in
            print("data", data)
            XCTAssertEqual(64, data.count)
            exp1.fulfill()
        }.catch{err in
            print("testRetreiveShares failed", err)
            XCTFail()
            exp1.fulfill()
        }
        
        wait(for: [exp1], timeout: 10)
    }
    
    // 8b288671081621975c9d4af918a15a5358a793c7bea4c066c37effe2f0c8d1ee unused private key
    
//    generateMetadataParams(message, privateKey) {
//        const key = this.ec.keyFromPrivate(privateKey.toString('hex', 64))
//        const setData = {
//            data: message,
//            timestamp: new BN(Date.now()).toString(16),
//        }
//        const sig = key.sign(keccak256(JSON.stringify(setData)).slice(2))
//        return {
//            pub_key_X: key.getPublic().getX().toString('hex'),
//            pub_key_Y: key.getPublic().getY().toString('hex'),
//            set_data: setData,
//            signature: Buffer.from(sig.r.toString(16, 64) + sig.s.toString(16, 64) + new BN(sig.v).toString(16, 2), 'hex').toString('base64'),
//        }
//    }
    
    func testSetMetadata(){
        
        let keystore = try! EthereumKeystoreV3(privateKey: Data(hex: "8b288671081621975c9d4af918a15a5358a793c7bea4c066c37effe2f0c8d1ee"))
        let setData = [
            "data": "8",
            "timestamp":  String(Int(Date().timeIntervalSince1970))
        ]
        // print(try! JSONSerialization.data(withJSONObject: setData, options: []))
        let setDataString = try! JSONSerialization.data(withJSONObject: setData, options: [])
        let hash = setDataString.sha3(.keccak256)
        let sign = SECP256K1.signForRecovery(hash: hash, privateKey: Data(hex: "8b288671081621975c9d4af918a15a5358a793c7bea4c066c37effe2f0c8d1ee"))
        let unmarshallSig = SECP256K1.unmarshalSignature(signatureData: sign.serializedSignature!)!
        print(String(data: unmarshallSig.r, encoding: .utf8))
        
        let newData = [
            "pub_key_X": "83ebc5515a6f3ad8d1d83c53b324afb7f88edc499e3bdbbd149492e460018292",
            "pub_key_Y": "a0de020d476f558d69e0b54ce83277df5f6305dbe065e337be313a51ad397958",
            "set_data": setData,
            "signature": "SECP256K1.unmarshalSignature(signatureData: sign)"
            ] as [String : Any]
        
//
//        let encoded = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
//        let rq = self.makeUrlRequest(url: "https://metadata.tor.us/set");
//        let request = URLSession.shared.uploadTask(.promise, with: rq, from: encoded)
//
//        let (tempPromise, seal) = Promise<BigInt>.pending()
//
//        request.compactMap {
//            try JSONSerialization.jsonObject(with: $0.data) as? [String: Any]
//        }.done{ data in
//            print("metdata response", data)
//            seal.fulfill(BigInt(data["message"] as! String, radix: 16)!)
//        }.catch{ err in
//            seal.fulfill(BigInt("1", radix: 16)!)
//        }
    }
    
    var allTests = [
        ("testKeyLookup", testKeyLookup),
        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress),
        ("testRetreiveShares", testRetreiveShares)
    ]
}
