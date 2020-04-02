import XCTest
import PromiseKit
import fetch_node_details
import CryptoSwift
import web3swift
import secp256k1

@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    
    var tempVerifierId = "shubham@tor.us"
    
    func testKeyLookup() {
        
        let expectation = self.expectation(description: "getting node details")

        let fd = Torus()
        let arr = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
        let key = fd.keyLookup(endpoints: arr, verifier: "google", verifierId: "somethinsdfgTest@g.com")
        key.done { data in
            print(data)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 6)
    }

    func testKeyAssign(){
        let expectations = self.expectation(description: "testing key assign")
        let fd = Torus()
        
        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]
        
        let keyAssign = fd.keyAssign(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], torusNodePubs: nodePubKeys, verifier: "google", verifierId: self.tempVerifierId)
        
        print(keyAssign)
        keyAssign.done{ data in
            print("data", data.result)
            expectations.fulfill()
        }.catch{ err in
            print("keyAssign failed", err)
        }
        waitForExpectations(timeout: 20)
    }
    
    func testingPromise() {
        testingAnotherrPromise().then{ data -> Promise<String> in
            print(data, "ASqweqd")
            return Promise<String>.value("this is a randomValue")
        }
    }
    
    func testingAnotherrPromise()-> Promise<String>{
        let (tempPromise, seal) = Promise<String>.pending()
        
        seal.fulfill("ASDF")
        tempPromise.then{ data -> Promise<String> in
            print("ASDF", data)
            return Promise<String>.value(data + "qweqwe")
        }
        return tempPromise
        print(tempPromise)
    }
    
    func testGetPublicAddress(){
        let expectations = self.expectation(description: "testing get public address")
        let fd = Torus()

        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]

        let getpublicaddress = fd.getPublicAddress(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], torusNodePubs: nodePubKeys, verifier: "google", verifierId: tempVerifierId, isExtended: true)

        print(getpublicaddress)
        getpublicaddress.done{ data in
            print("data", data)
            expectations.fulfill()
        }.catch{ err in
            print("getpublicaddress failed", err)
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSecp(){
//        let key = SECP256K1.generatePrivateKey()
//        let publicKey = SECP256K1.privateToPublic(privateKey: key!, compressed: false)
//        let publicKeyHex = publicKey?.toHexString()
//
//        let cleanKey = publicKey!.suffix(publicKey!.count - 1)
//        let pubKeyUnHashed = cleanKey.suffix(cleanKey.count - 2)
//        let pubData = Data.init(hex: pubKeyUnHashed)
//        print(cleanKey)
//        print(key?.toHexString(), cleanKey.sha3(SHA3.Variant.keccak256).bytes.toHexString())
//
//        let publicAddress = Web3.Utils.publicToAddress(publicKey!)
//        print(publicAddress?.address)
        
        
        let privateKey = SECP256K1.generatePrivateKey()
        let tempPubKey = SECP256K1.privateToPublic(privateKey: privateKey!, compressed: false)
        
        let publicKey = tempPubKey!.suffix(tempPubKey!.count - 1)
        let publicKeyHex = publicKey.toHexString()
        let pubKeyX = publicKey.prefix(publicKey.count/2)
        let pubKeyY = publicKey.suffix(publicKey.count/2)
        
        print(publicKey, publicKeyHex, pubKeyX.toHexString(), pubKeyY.toHexString())
        
        let publicAddress = Web3.Utils.publicToAddress(publicKey)
        print(publicAddress?.address)
    }
    
    func testretreiveShares(){
        let expectations = self.expectation(description: "testing get public address")
        let fd = Torus()
        let verifierParams = ["verifier_id": tempVerifierId]
        let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N2Y2YTU4MjhkMWU0YTNhNmEwM2ZjZDFhMjQ2MWRiOTU5M2U2MjQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6InE4aGdGQUxmM1NIRVE5SFk3cXJIcUEiLCJub25jZSI6IlU2SEZ4eFRLUVNwdVNpbDlrM1VoeVVYSERXNm1wTSIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQUFLV0pKTmVleHhiRHozcjFVVnBrWjVGbzdsYTNhMXZRZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4NTgyMTY2NywiZXhwIjoxNTg1ODI1MjY3LCJqdGkiOiI3MGEyMmFjM2I2M2FlNGUyNGZjNjY2ZmZiM2Q4OTdlNTU4ZmY0ZWQ3In0.cUHsCRwLiUs2WciknntOXyHBampPpOLH3Mdwd9HweMQXcjFZsfcYUXhO2M8otRk2lO6czwcfoJXyHueVk_mSP_mAmXcGFEHGfjwf6lpjIyJuyMvJbO5DPVrWn_aiBwFe-cB_Lfu9XBI6bnbjmuxeh8how_p4idjw-h_J3R9xlpTc-_Zmmp8jJlP0jHRb3Ci6uDSKevs80U2PfXi1FWfJvmO348jBJKQOPZLCwdw-xwr0Gcv6_sl9PrHJgFZUsXtF-tpASwGWAPnJ9HhqSvFcrK26u6qkhwAfTTM2qkcrcn9-JsMlml72Y-TzkoxA4daadya1sKUB-Gh1p372GWWvaQ"
        
        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]

        let retreiveShares = fd.retreiveShares(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], verifier: "google", verifierParams: verifierParams, idToken: token)
//
//        print(getpublicaddress)
//        getpublicaddress.done{ data in
//            print("data", data)
//            expectations.fulfill()
//        }.catch{ err in
//            print("getpublicaddress failed", err)
//        }
        waitForExpectations(timeout: 10)
    }
    
    static var allTests = [
        ("testretreiveShares", testretreiveShares),
        ("testingPromise", testingPromise),
        ("testSecp", testSecp),
//        ("testKeyLookup", testKeyLookup),
//        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress)
    ]
}
