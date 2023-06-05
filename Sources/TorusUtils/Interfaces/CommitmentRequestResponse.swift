import Foundation

public struct CommitmentRequestResponse: Decodable {
    public var data: String
    public var nodepubx: String
    public var nodepuby: String
    public var signature: String

    public init(data: String, nodepubx: String, nodepuby: String, signature: String) {
        self.data = data
        self.nodepubx = nodepubx
        self.nodepuby = nodepuby
        self.signature = signature
    }
}

extension Array where Element == CommitmentRequestResponse {

    public func tostringDict() -> [[String: String]] {
        var dictArr = [[String: String]]()
        for val in self {
            var dict = [String: String]()
            dict["data"] = val.data
            dict["nodepubx"] = val.nodepubx
            dict["nodepuby"] = val.nodepuby
            dict["signature"] = val.signature
            dictArr.append(dict)
        }
        return dictArr
    }
}
