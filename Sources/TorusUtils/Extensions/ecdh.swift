import Foundation
#if canImport(secp256k1)
    import secp256k1
#endif

extension secp256k1 {
    public static func ecdh(publicKey: secp256k1.KeyAgreement.PublicKey, privateKey: secp256k1.KeyAgreement.PrivateKey) throws -> [UInt8] {
        let copyx: secp256k1.KeyAgreement.PrivateKey.HashFunctionType = {
            out, x, _, _ -> Int32 in
            guard let out = out, let x = x else {
                return 0
            }
            out.initialize(from: x, count: 32)
            return 1
        }
        
        let sharedSecret = try! privateKey.sharedSecretFromKeyAgreement(with: publicKey, handler: copyx)
        let hash = sharedSecret.bytes.sha512()
        
        return hash
    }
    
    public static func ecdhWithHex(pubKeyHex: String, privateKeyHex: String) throws -> [UInt8] {
        let privateKeyBytes = try privateKeyHex.bytes
        let privateKey = try secp256k1.KeyAgreement.PrivateKey(dataRepresentation: privateKeyBytes)
        
        let publicKeyBytes = try pubKeyHex.bytes
        let publicKey = try secp256k1.KeyAgreement.PublicKey(dataRepresentation: publicKeyBytes, format: .uncompressed)
        
        let sharedSecret = try ecdh(publicKey: publicKey, privateKey: privateKey)
        return sharedSecret
    }
}
