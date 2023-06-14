import Foundation
import BigInt

func keccak256Data(_ data: Data) -> String {
    let hash = data.sha3(.keccak256)
    return "0x" + hash.map { String(format: "%02x", $0) }.joined()
}

func stripHexPrefix(_ str: String) -> String {
    return str.hasPrefix("0x") ? String(str.dropFirst(2)) : str
}

func toChecksumAddress(_ hexAddress: String) -> String {
    let address = stripHexPrefix(hexAddress).lowercased()
    let data = Data(address.utf8)
    let hash = keccak256Data(data)
    var ret = "0x"
    
    for (i, char) in address.enumerated() {
        let hashChar = hash[hash.index(hash.startIndex, offsetBy: i)]
        if let hexValue = UInt8(String(hashChar), radix: 16), hexValue >= 8 {
            ret.append(char.uppercased())
        } else {
            ret.append(char)
        }
    }
    
    return ret
}

// WIP
func generateAddressFromPrivateKey(privateKey: Data) {
    let pubKey = SECP256K1.privateToPublic(privateKey: privateKey)?.toHexString().dropFirst(2)
    let ethAddressLower = "0x" + keccak256Data(Array(hexString: pubKey)).suffix(38)
    return toChecksumAddress(ethAddressLower)
    
}

func generateAddressFromPubKey(publicKeyX: BigInt, publicKeyY: BigInt) {
    
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
