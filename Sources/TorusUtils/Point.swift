import Foundation
import CryptorECC
import BigInt
import Security

extension Data {
    init?(hex: String) {
        var hexString = hex
        // Remove any prefix or whitespace
        hexString = hexString.replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        // Ensure the hex string has an even number of characters
        guard hexString.count % 2 == 0 else { return nil }
        
        // Convert each 2 characters into a byte and append to data
        var data = Data()
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        self = data
    }
}

class Point {
    let x: BigInt
    let y: BigInt
    let ecCurve: EllipticCurve

    init(x: BNString, y: BNString, ecCurve: EllipticCurve) {
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
        
        self.ecCurve = ecCurve
    }

    func encode(enc: String) throws -> Data {
        switch enc {
        case "arr":
            let prefix = Data(hex: "04")!
            let xData = Data(hex: x.description)!
            let yData = Data(hex: y.description)!
            return prefix + xData + yData
        case "elliptic-compressed":
            let publicKey = try getCompressedPublicKey()
            return publicKey
        default:
            throw PointError.encodingNotSupported
        }
    }
    
    private func getCompressedPublicKey() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(ecCurve as! SecKey, &error) as Data? else {
            throw PointError.compressedPublicKeyGenerationFailed
        }
        
        let compressedPublicKeyData = publicKeyData.subdata(in: 9..<publicKeyData.count)
        return compressedPublicKeyData
    }
}

enum PointError: Error {
    case encodingNotSupported
    case compressedPublicKeyGenerationFailed
}
