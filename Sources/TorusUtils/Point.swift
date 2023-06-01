import Foundation
import CryptoKit
import Security

struct Point {
    let x: Data
    let y: Data
    
    init(x: String, y: String) {
        self.x = Data(hexString: x)!
        self.y = Data(hexString: y)!
    }
    
    func encode(enc: String) throws -> Data {
        switch enc {
        case "arr":
            let prefix = Data(hexString: "04")!
            return prefix + x + y
        case "elliptic-compressed":
            do {
                let publicKeyData = try createCompressedPublicKey(x: x, y: y)
                return publicKeyData
            } catch {
                throw error
            }
        default:
            throw EncodingError.unknownEncoding
        }
    }
    
    private func createCompressedPublicKey(x: Data, y: Data) throws -> Data {
        guard let ecPublicKeyData = ECPointData(x: x, y: y) else {
            throw EncodingError.unableToCreatePublicKey
        }
        
        let publicKeyData = SecKeyCreateWithData(ecPublicKeyData as CFData, [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 256,
            kSecUseDataProtectionKeychain: false
        ] as CFDictionary, nil)
        
        return publicKeyData! as Data
    }
}

enum EncodingError: Error {
    case unknownEncoding
    case unableToCreatePublicKey
}
