import Foundation
import BigInt
import CryptorECC

func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
    guard let params = params, let message = params["message"] as? String else {
        return BigUInt(0)
    }
    return BigUInt(message, radix: 16)
}

func decryptNodeData(ciphertextHex: String, privateKey: String) -> String? {
    if let ciphertextData = Data(hex: ciphertextHex) {
        guard let ecPrivateKey = try? ECPrivateKey(key: privateKey) else { return nil }
        guard let decryptedData = try? ciphertextData.decrypt(with: ecPrivateKey) else {
            return nil
        }
        let decryptedStr = String(data: decryptedData, encoding: .utf8)
        return decryptedStr
    } else {
        return nil
    }
}
