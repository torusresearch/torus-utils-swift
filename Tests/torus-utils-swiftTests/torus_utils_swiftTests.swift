import XCTest
@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let expectation = self.expectation(description: "getting node details")

        
        let fd = Torus()
        let arr = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
        fd.keyLookup(endpoints: arr, verifier: "google", verifierId: "shubham@tor.us")
        
        waitForExpectations(timeout: 6)

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
