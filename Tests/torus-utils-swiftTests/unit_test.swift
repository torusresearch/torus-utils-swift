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

final class torus_utils_swiftTests: XCTestCase {
    
    let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    let nodeList = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
    let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")]
    let verifierId = "shubham@tor.us"
    let verifier = "google"
    let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc0YmQ4NmZjNjFlNGM2Y2I0NTAxMjZmZjRlMzhiMDY5YjhmOGYzNWMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6ImxRN2taQXpMNnJOZzkxZXBtTXNWVWciLCJub25jZSI6ImR6eE9NazJMZ25CVnNLeEVjWW9XUFZWcmdsV1ViQiIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQUFLV0pKTmVleHhiRHozcjFVVnBrWjVGbzdsYTNhMXZRZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4ODU4Nzg0NCwiZXhwIjoxNTg4NTkxNDQ0LCJqdGkiOiI1Yzg3ZWI0NjA3YzY0OGI3NTkwYTFiMzRkNzAxNWRlMGVjYjJmYjgyIn0.TXVX01HdJnIERxvqmN3myIAjB0YVDdr16sk5TDFGjUaTWQxwu1LB2TGbWgNLOBmITzeXWhnQtm8pSfUYTdDu1fbrRJ27tRsB1clYUdvsGpob16h3rsUWx8ZbkNFze67zT2jcd2eW2cTkMs2j5Lb4L2cPgMj1zdXK_FcvX4iYkyrKLAhOCQOJHBZO8fi5YCqvG3-sP3UOWpf9WhlcXe_FSR_DTO7WIR3071ki4nY-s1HIXczLcLlpWE3csWXAk6R96nB1VkrkbmM8ASvceMdbRSyPWu2LcQdk92fjwQqy0YFf7v7IiFepKHmkl9xd7v7toerbw-BWPJnRZ60W6tIqVA"
    
    override class func setUp() {
        super.setUp()
        let fnd = FetchNodeDetails()
        // self.nodeList = fnd.getNodeDetails().getTorusNodeEndpoints()
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
    
    func testRetreiveShares(){
        let exp1 = XCTestExpectation(description: "reterive privatekey")
        let obj = TorusUtils()
        let key = obj.retreiveShares(endpoints: self.nodeList, verifier: "google", verifierParams: ["verifier_id":"shubham@tor.us"], idToken: token)
        key.done{ data in
            print("data", data)
            XCTAssertEqual(64, data.count)
            exp1.fulfill()
        }.catch{err in
            print("Unit test, testRetreiveShares", err)
        }
        
        wait(for: [exp1], timeout: 20)
    }
    
    var allTests = [
        ("testKeyLookup", testKeyLookup),
        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress)
    ]
}
