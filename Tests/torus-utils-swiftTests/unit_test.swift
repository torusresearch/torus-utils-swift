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
    let verifier = "google-shubs"
    let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc0YmQ4NmZjNjFlNGM2Y2I0NTAxMjZmZjRlMzhiMDY5YjhmOGYzNWMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIyMzg5NDE3NDY3MTMtcXFlNGE3cmR1dWsyNTZkOG9pNWwwcTM0cXR1OWdwZmcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIyMzg5NDE3NDY3MTMtcXFlNGE3cmR1dWsyNTZkOG9pNWwwcTM0cXR1OWdwZmcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6IjY2bXVLVS1NTzNmTjFNbV9LdnhJWHciLCJub25jZSI6IjEyMyIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQUFLV0pKTmVleHhiRHozcjFVVnBrWjVGbzdsYTNhMXZRZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4ODY2ODUzOSwiZXhwIjoxNTg4NjcyMTM5LCJqdGkiOiJlOWE1MWFlYmI3ZGQ1ODViM2I3MGUyYjlhOTBiNGI1ZGVhOTI0MTAyIn0.L9fj59OMTNL6NomQ8KCu6HKaxEQoFmPfQIPMrZ4xCcrYTU7WNeVJS8yyimebM_vj0UcamoNhdTInJ6qBnVrJOTbmztsK-7g6pc5gCiQuXJVBNARqnFtFc7USOQawQB6t4NoxgY387dlOBGTgdQa-TvQ4qu5kUTzSSSFymLpr-p7seWE4aL0HHlaujlNXlcE_yJBFgwraLxbUE7U9BMAcrOhyaB1zNkYYQlJZiwDjQb19cWYOMq_TYtF0VvxHXrTcNhxqZ-tHdcYS-bBH0yO8KMUe2D3nD0zcHGtrf2m_dbR2VEjXJaOH5Xv3gZnzi8JkLvdlyzNe0ufiCkGeAigE7g"
    
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
        let obj = TorusUtils()
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
        let obj = TorusUtils()
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
        let obj = TorusUtils()
        let key = obj.retreiveShares(endpoints: self.nodeList, verifier: verifier, verifierParams: ["verifier_id": verifierId], idToken: token)
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
    
    var allTests = [
        ("testKeyLookup", testKeyLookup),
        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress),
        ("testRetreiveShares", testRetreiveShares)
    ]
}
