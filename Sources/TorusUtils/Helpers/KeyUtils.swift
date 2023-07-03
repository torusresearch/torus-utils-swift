import Foundation
import CryptoKit
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

func generateAddressFromPrivKey(privateKey: String) -> String {
    do {
        let privateKeyData = Data(hexString: privateKey)!
        let key = try P256.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
        let publicKey = key.publicKey.rawRepresentation.dropFirst().dropLast() // Remove the first byte (0x04)
        let ethAddressLower = "0x" + keccak256Data(publicKey).suffix(38)
        return ethAddressLower
    } catch {
        // Handle the error if necessary
        print("Failed to generate address from private key: \(error)")
        return ""
    }
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) -> String {
    let publicKeyHex = "04" + publicKeyX.addLeading0sForLength64()  + publicKeyY.addLeading0sForLength64()
    let publicKeyData = Data(hexString: publicKeyHex)!
    
    do {
        let publicKey = try P256.KeyAgreement.PublicKey(x963Representation: publicKeyData)
        let publicKeyBytes = publicKey.rawRepresentation.dropFirst().dropLast() // Remove the first byte (0x04)
        let ethAddressLower = "0x" + keccak256Data(publicKeyBytes).suffix(38)
        return ethAddressLower
    } catch {
        // Handle the error if necessary
        print("Failed to derive public key: \(error)")
        return ""
    }
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


//import Foundation
//import secp256k1
//import CryptoKit
//
//func getPublicAddressFromCoordinates(x: String, y: String) -> String? {
//    guard let xData = Data(hexString: x),
//          let yData = Data(hexString: y) else {
//        return nil
//    }
//
//    // Combine the x and y coordinates into a single data object
//    let publicKeyData = xData + yData
//
//    // Convert the combined data to a CryptoKit elliptic curve public key
//    let publicKey = P256.Signing.PublicKey(rawRepresentation: publicKeyData)
//
//    // Compute the public address using the hash of the public key
//    let addressData = Data(SHA256.hash(data: publicKey.rawRepresentation))
//    let address = addressData.suffix(20).hexString  // Take the last 20 bytes as the address
//
//    return address
//}
//
//// Extension to convert Data to hex string representation
//extension Data {
//    init?(hexString: String) {
//        let string = hexString.trimmingCharacters(in: .whitespaces)
//        var data = Data(capacity: string.count / 2)
//
//        var index = string.startIndex
//        while index < string.endIndex {
//            let byteString = string[index ..< string.index(index, offsetBy: 2)]
//            guard let byte = UInt8(byteString, radix: 16) else {
//                return nil
//            }
//            data.append(byte)
//            index = string.index(index, offsetBy: 2)
//        }
//        self = data
//    }
//
//    var hexString: String {
//        return map { String(format: "%02hhx", $0) }.joined()
//    }
//}
//
//// Usage example
//let xCoordinate = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"
//let yCoordinate = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e"
//
//if let publicAddress = getPublicAddressFromCoordinates(x: xCoordinate, y: yCoordinate) {
//    print("Public Address:", publicAddress)
//} else {
//    print("Invalid coordinates")
//}
