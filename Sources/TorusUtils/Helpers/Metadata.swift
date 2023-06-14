import Foundation
import BigInt
import CryptoKit

func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
    guard let params = params, let message = params["message"] as? String else {
        return BigUInt(0)
    }
    return BigUInt(message, radix: 16)!
}


func decryptNodeData(eciesData: EciesHexOmitCiphertext, ciphertextHex: String, privKey: Data) throws -> Data {
    let metadata = encParamsHexToBuf(eciesData: eciesData)
    guard let ciphertext = Data(hexString: ciphertextHex) else {
        throw DecryptionError.invalidCiphertext
    }
    let eciesOpts = Ecies(
        iv: metadata.iv,
        ephemPublicKey: metadata.ephemPublicKey,
        ciphertext: ciphertext,
        mac: metadata.mac
    )
    let decryptedSigBuffer = try decryptOpts(privateKey: privKey, opts: eciesOpts)
    return decryptedSigBuffer
}

enum DecryptionError: Error {
    case invalidCiphertext
}
