import Foundation
import BigInt
import Security

class Point {
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
