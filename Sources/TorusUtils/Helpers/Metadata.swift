import Foundation
import BigInt
import CryptorECC

func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
    guard let params = params, let message = params["message"] as? String else {
        return BigUInt(0)
    }
    return BigUInt(message, radix: 16) ?? BigUInt(0)
}

func decryptNodeData(encryptedMessage: String, privateKey: String) -> String? {
    guard let privateKeyData = Data(base64Encoded: privateKey),
          let encryptedData = Data(base64Encoded: encryptedMessage) else {
        return nil
    }
    
    let privateKey = ECPrivateKey(raw: privateKeyData)
    let decryptedData = try? encryptedData.decrypt(with: privateKey)
    
    return decryptedData?.utf8String
}
