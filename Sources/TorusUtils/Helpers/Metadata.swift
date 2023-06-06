import Foundation
import BigInt
import CryptorECC

func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
    guard let params = params, let message = params["message"] as? String else {
        return BigUInt(0)
    }
    return BigUInt(message, radix: 16) ?? BigUInt(0)
}

func decryptNodeData(ciphertextHex: String, privateKey: String) -> String? {
    guard let ciphertextData = Data(hex: ciphertextHex) else {
        return nil
    }
    guard let ecPrivateKey = try? ECPrivateKey(key: privateKey) else { return nil }
    let decryptedData = try? ciphertextData.decrypt(with: ecPrivateKey)
    return decryptedData?.utf8String
}
