import Foundation
import BigInt
import Security

public class Point : Decodable  {
    let x: BigInt
    let y: BigInt

    init(x: String, y: String) {
        self.x = BigInt(x, radix: 16)!
        self.y = BigInt(y, radix: 16)!
    }
    
    init(x: BigInt, y: BigInt) {
        self.x = x
        self.y = y
    }
    
    
    public enum CodingKeys: CodingKey {
        case X
        case Y
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hexX = try container.decode(String.self, forKey: .X)
        let hexY = try container.decode(String.self, forKey: .Y)
        
        self.x = BigInt(hexX, radix: 16)!
        self.y = BigInt(hexY, radix: 16)!
    }
    
    func encode(enc: String) throws -> Data {
        switch enc {
        case "arr":
            let prefix = Data(hex: "0x04")!
            let xData = Data(hex: x.description)!
            let yData = Data(hex: y.description)!
            return prefix + xData + yData
//        case "elliptic-compressed":
//            let publicKey = try getCompressedPublicKey()
//            return publicKey
        default:
            throw PointError.encodingNotSupported
        }
    }
}

public struct PointHex : Decodable, Hashable, Equatable {
    let x: String
    let y: String
    
    init(from: Point) {
        x = from.x.serialize().hexString
        y = from.x.serialize().hexString
    }
}

enum PointError: Error {
    case encodingNotSupported
    case compressedPublicKeyGenerationFailed
}
