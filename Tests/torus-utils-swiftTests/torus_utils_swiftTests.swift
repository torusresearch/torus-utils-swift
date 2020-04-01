import XCTest
import PromiseKit
import fetch_node_details
@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    
    var tempVerifierId = "new1@m.com"
    
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
        waitForExpectations(timeout: 20)
    }
    
    static var allTests = [
        ("testingPromise", testingPromise),
//        ("testKeyLookup", testKeyLookup),
//        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress)
    ]
}
