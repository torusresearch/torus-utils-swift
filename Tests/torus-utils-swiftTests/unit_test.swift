import XCTest
import PromiseKit
import fetch_node_details
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
@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    
    let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    let nodeList = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
    let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")]
    let verifierId = "shubham@tor.us"
    let verifier = "google"
    let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N2Y2YTU4MjhkMWU0YTNhNmEwM2ZjZDFhMjQ2MWRiOTU5M2U2MjQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6IkppMUN5RG90Z1FGUWJRcG80aGxSeUEiLCJub25jZSI6Ik9CWEZsaGw5SnJKMjJvOVRpUG5mUW91WUVTcHp6dyIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQUFLV0pKTmVleHhiRHozcjFVVnBrWjVGbzdsYTNhMXZRZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4NjQyMTg1NSwiZXhwIjoxNTg2NDI1NDU1LCJqdGkiOiI1YWViMGIyNjM2NjUzNGYxNDFhMDM2ZGEyN2FjYTYzOTcyNzY1ZGI4In0.ST--Qo4Q8SKQjaE0PD6WGJWA97l1SklPa4v7dWg0ScU8nvkCZokh0qCnJfMSijExemn0OiExXzw7QNhzUsR04y39dSh32ZE3GT6JddmSkyte9ez3dNcXEv0KqdxfX_kjz6ePwKkbwWvTKumCir0vQR_kW-o2vfUwr5VXIGReRfdYDIeaCqtZovEf7sm5PvL7VyS7tGVk2CIYAyivU7RH2CKtyRGedyR3gz68aTGyB5zHYpblu2g9FKfk18t2uDzzKVkDk1uYjRu04wVqwFlXt4YLypzbl8cTuEjtaw6PqH8PggSR9zw00LsGf21F66f8xk5HTEi4vBAb9OC8HrdOoA"
    
    override class func setUp() {
        super.setUp()
        let fnd = fetch_node_details.FetchNodeDetails()
        print(fnd.getNodeDetails().getTorusNodeEndpoints())
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
        }
        
        let exp2 = XCTestExpectation(description: "Do keylookup with failure")
        let keyLookupFailure = obj.keyLookup(endpoints: nodeList, verifier: self.verifier, verifierId: self.verifierId + "someRandomString")
        keyLookupFailure.done { data in
            XCTAssert(data["err"]=="keyLookupfailed", "error verified")
            exp2.fulfill()
        }.catch{err in
            print(err)
        }
    
        wait(for: [exp1, exp2], timeout: 5)
    }
    
    func testKeyAssign(){
        let exp1 = XCTestExpectation(description: "Do keyAssign success")
        let obj = TorusUtils()
        let keyAssign = obj.keyAssign(endpoints: self.nodeList, torusNodePubs: nodePubKeys, verifier: verifier, verifierId: self.verifierId)
        keyAssign.done{ data in
            XCTAssertNotNil(data)
            exp1.fulfill()
        }.catch{ err in
            print("keyAssign failed", err)
        }
        wait(for: [exp1], timeout: 5)
    }
    
    func testGetPublicAddress(){
        let exp1 = XCTestExpectation(description: "testing get public address")
        let obj = TorusUtils()
        let getpublicaddress = obj.getPublicAddress(endpoints: self.nodeList, torusNodePubs: nodePubKeys, verifier: "google", verifierId: self.verifierId, isExtended: true)
        getpublicaddress.done{ data in
            print("data", data)
            XCTAssert(data["address"]=="0x5533572d0b2b69Ae31bfDeA351B67B1C05F724Bc", "Address verified")
            exp1.fulfill()
        }.catch{ err in
            print("getpublicaddress failed", err)
        }
        
        wait(for: [exp1], timeout: 10)
    }
    
    var allTests = [
        ("testKeyLookup", testKeyLookup),
        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress)
    ]
}
