import Foundation
import CryptoKit
import BigInt

func keccak256Data(_ data: Data) -> Data {
    return data.sha3(.keccak256)
}

func keccak256Hex(_ data: Data) -> String {
    let hash = keccak256Data(data)
    return "0x" + hash.map { String(format: "%02x", $0) }.joined()
}

func stripHexPrefix(_ str: String) -> String {
    return str.hasPrefix("0x") ? String(str.dropFirst(2)) : str
}

struct BasePoint {
    let x: Data
    let y: Data
    
    public func add(_ other: BasePoint) -> BasePoint? {
        let x1 = self.x
        let y1 = self.y
        let x2 = other.x
        let y2 = other.y
        
        let bigX1 = BigInt(x1)
        let bigY1 = BigInt(y1)
        let bigX2 = BigInt(x2)
        let bigY2 = BigInt(y2)
        
        let sumX = (bigX1 + bigX2).serialize().toHexString().data(using: .utf8)!
        let sumY = (bigY1 + bigY2).serialize().toHexString().data(using: .utf8)!
        
        return BasePoint(x: sumX, y: sumY)
    }
    
    public func fromPublicKeyComponents(x: String, y: String) -> BasePoint {
        return BasePoint(x: Data(hex: x.addLeading0sForLength64()), y: Data(hex: y.addLeading0sForLength64()))
    }
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) throws -> String {
    let publicKeyHex = publicKeyX.addLeading0sForLength64()  + publicKeyY.addLeading0sForLength64()
    guard let publicKeyData = Data(hexString: publicKeyHex)
    else {
        throw TorusUtilError.runtime("Invalid public key when deriving etherium address")
    }
    let ethAddrData = publicKeyData.sha3(.keccak256).suffix(20)
    let ethAddrlower = "0x" + ethAddrData.toHexString()
    return ethAddrlower.toChecksumAddress()
}

func getPostboxKeyFrom1OutOf1(privKey: String, nonce: String) -> String {
    guard let privKeyBigInt = BigInt(privKey, radix: 16),
          let nonceBigInt = BigInt(nonce, radix: 16),
          let modulus = BigInt(CURVE_N, radix: 16) else {
        return ""
    }
    
    let result = (privKeyBigInt - nonceBigInt).modulus(modulus)
    return result.serialize().toHexString()
}
