import BigInt
import Foundation

public struct TaskGroupResponse {
   public var data: Data
   public var urlResponse: URLResponse
   public var index: Int

    public init(data: Data, urlResponse: URLResponse, index: Int) {
        self.data = data
        self.urlResponse = urlResponse
        self.index = index
    }
}

public enum TypeOfUser: String {
    case v1
    case v2
}

public struct GetUserAndAddress {
    public var typeOfUser: TypeOfUser
    public var pubNonce: PubNonce?
    public var nonceResult: String?
    public var address: String
    public var x: String
    public var y: String

    public init(typeOfUser: TypeOfUser, address: String, x: String, y: String, pubNonce: PubNonce? = nil, nonceResult: String? = nil) {
        self.typeOfUser = typeOfUser
        self.address = address
        self.x = x
        self.y = y
        self.pubNonce = pubNonce
        self.nonceResult = nonceResult
    }
}

public struct GetPublicAddressResult {
    public var address: String
    public var typeOfUser: TypeOfUser?
    public var x: String?
    public var y: String?
    public var metadataNonce: BigUInt?
    public var pubNonce: PubNonce?

    public init(address: String, typeOfUser: TypeOfUser? = nil, x: String? = nil, y: String? = nil, metadataNonce: BigUInt? = nil, pubNonce: PubNonce? = nil) {
        self.typeOfUser = typeOfUser
        self.address = address
        self.x = x
        self.y = y
        self.metadataNonce = metadataNonce
        self.pubNonce = pubNonce
    }
}

public struct GetOrSetNonceResult: Decodable {
    public var typeOfUser: String
    public var nonce: String?
    public var pubNonce: PubNonce?
    public var ifps: String?
    public var upgraded: Bool?

    public init(typeOfUser: String, nonce: String? = nil, pubNonce: PubNonce? = nil, ifps: String? = nil, upgraded: Bool? = nil) {
        self.typeOfUser = typeOfUser
        self.nonce = nonce
        self.pubNonce = pubNonce
        self.ifps = ifps
        self.upgraded = upgraded
    }
}

public struct PubNonce: Decodable {
    public var x: String
    public var y: String

    public init(x: String, y: String) {
        self.x = x
        self.y = y
    }
}

public struct UserTypeAndAddress {
    public var typeOfUser: String
    public var nonce: BigInt?
    public var x: String
    public var y: String
    public var address: String

    public init(typeOfUser: String, x: String, y: String, nonce: BigInt?, address: String) {
        self.typeOfUser = typeOfUser
        self.address = address
        self.x = x
        self.y = y
        self.nonce = nonce
    }
}

public enum BNString {
    case string(String)
    case bn(BigInt)
    
    func toString() -> String? {
        switch self {
        case .string(let str):
            return str
        case .bn(let bigint):
            return String(bigint)
        }
    }
}

typealias StringifiedType = [String: Any]
