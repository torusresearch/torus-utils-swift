import XCTest
@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    func testExample() {
        
        let expectation = self.expectation(description: "getting node details")

        let fd = Torus()
        let arr = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
        let key = fd.keyLookup(endpoints: arr, verifier: "google", verifierId: "shubhaffm@tor.us")
//        var result : String
        key.done { data in
//            result = data
            print(data)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 6)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
