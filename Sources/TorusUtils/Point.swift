import BigInt
import Foundation
import Security
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

enum PointError: Error {
    case encodingNotSupported
    case compressedPublicKeyGenerationFailed
}

internal struct Point: Codable {
    let x: BigInt
    let y: BigInt

    init(x: String, y: String) throws {
        if let xCoord = BigInt(x, radix: 16) {
            self.x = xCoord
        } else {
            throw TorusUtilError.invalidInput
        }

        if let yCoord = BigInt(y, radix: 16) {
            self.y = yCoord
        } else {
            throw TorusUtilError.invalidInput
        }
    }

    init(x: BigInt, y: BigInt) {
        self.x = x
        self.y = y
    }

    enum CodingKeys: CodingKey {
        case X
        case Y
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hexX = try container.decode(String.self, forKey: .X)
        let hexY = try container.decode(String.self, forKey: .Y)

        x = BigInt(hexX, radix: 16)!
        y = BigInt(hexY, radix: 16)!
    }

    func encode(enc: String) throws -> Data {
        switch enc {
        case "arr":
            return Data(hex: KeyUtils.getPublicKeyFromCoords(pubKeyX: x.magnitude.serialize().hexString, pubKeyY: y.magnitude.serialize().hexString))
        case "elliptic-compressed":
            let keyData = KeyUtils.getPublicKeyFromCoords(pubKeyX: x.magnitude.serialize().hexString, pubKeyY: y.magnitude.serialize().hexString)
            let pubKey = try PublicKey(hex: keyData)
            return Data(hex: try pubKey.serialize(compressed: true))
        default:
            throw PointError.encodingNotSupported
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x.magnitude.serialize().hexString.addLeading0sForLength64(), forKey: .X)
        try container.encode(y.magnitude.serialize().hexString.addLeading0sForLength64(), forKey: .Y)
    }
}

internal struct PointHex: Decodable, Hashable, Equatable {
    let x: String
    let y: String

    init(from: Point) {
        x = String(from.x, radix: 16)
        y = String(from.y, radix: 16)
    }
}
