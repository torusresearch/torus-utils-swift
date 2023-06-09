import Foundation
import BigInt
import Security

class Point {
    let x: BigInt
    let y: BigInt

    init(x: BNString, y: BNString) {
        switch x {
        case .string(let xStr):
            self.x = BigInt(xStr, radix: 16)!
        case .bn(let xBigInt):
            self.x = xBigInt
        }
        
        switch y {
        case .string(let yStr):
            self.y = BigInt(yStr, radix: 16)!
        case .bn(let yBigInt):
            self.y = yBigInt
        }
        
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

enum PointError: Error {
    case encodingNotSupported
    case compressedPublicKeyGenerationFailed
}
