import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(torus_utils_swiftTests.allTests),
        ]
    }
#endif
