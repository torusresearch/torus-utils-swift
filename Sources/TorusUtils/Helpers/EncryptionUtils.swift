import Foundation

#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

public class EncryptionUtils {
    
    public static func decryptNodeData(eciesData: EciesHexOmitCiphertext, ciphertextHex: String, privKey: String) throws -> String {
        let eciesOpts = ECIES(
            iv: eciesData.iv,
            ephemPublicKey: eciesData.ephemPublicKey,
            ciphertext: ciphertextHex,
            mac: eciesData.mac
        )

        let decryptedSigBuffer = try decrypt(privateKey: privKey, opts: eciesOpts).hexString
        return decryptedSigBuffer
    }

    public static func decrypt(privateKey: String, opts: ECIES) throws -> Data {
        let secret = try SecretKey(hex: privateKey)
        var publicKey = opts.ephemPublicKey
        if opts.ephemPublicKey.count == 128 { // missing 04 prefix
            publicKey = publicKey.add04PrefixUnchecked()
        }
        let msg = try EncryptedMessage(cipherText: opts.ciphertext, ephemeralPublicKey: PublicKey(hex: publicKey), iv: opts.iv, mac: opts.mac)
        let result = try Encryption.decrypt(sk: secret, encrypted: msg)
        return result
    }

    public static func encrypt(publicKey: String, msg: String) throws -> Ecies {
        let data = Data(hex: msg)
        let curveMsg = try Encryption.encrypt(pk: PublicKey(hex: publicKey), plainText: data)
        return try .init(iv: curveMsg.iv(), ephemPublicKey: curveMsg.ephemeralPublicKey().serialize(compressed: false), ciphertext: curveMsg.chipherText(), mac: curveMsg.mac())
    }
}
