import Foundation
#if canImport(curvelib_swift)
    import curvelib_swift
#endif

public struct CurveSecp256k1 {}

extension CurveSecp256k1 {
    public static func ecdh(publicKey: PublicKey, privateKey: SecretKey) throws -> [UInt8] {
        let shared = try publicKey.mul(key: privateKey)
        let serialized = try shared.serialize(compressed: true)
        let data = Data(hex: serialized).dropFirst()
        return data.bytes.sha512()
    }

    public static func ecdhWithHex(pubKeyHex: String, privateKeyHex: String) throws -> [UInt8] {

        let sharedSecret = try ecdh(publicKey: PublicKey(hex: pubKeyHex), privateKey: SecretKey(hex: privateKeyHex))
        return sharedSecret
    }

    public static func privateToPublic(privateKey: SecretKey, compressed: Bool = false) throws -> String {
        let publicKey = try privateKey.to_public()
        return try publicKey.serialize(compressed: compressed)
    }

    private static func constantTimeComparison(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference = UInt8(0x00)
        for i in 0 ..< lhs.count { // compare full length
            difference |= lhs[i] ^ rhs[i] // constant time
        }
        return difference == UInt8(0x00)
    }

    private static func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }

    public static func verifyPrivateKey(privateKey: String) -> Bool {
        do {
            _ = try SecretKey(hex: privateKey)
            return true;
        } catch (_) {
            return false;
        }
    }

    public static func recoverPublicKey(hash: String, signature: String, compressed: Bool = false) throws -> String {
        let sig = try Signature(hex: signature)
        debugPrint(try sig.serialize())
        return try ECDSA.recover(signature: sig, hash: hash).serialize(compressed: compressed)
    }

    public static func parseSignature(signature: String) throws -> curvelib_swift.Signature {
        return try Signature(hex: signature)
    }

    internal static func serializeSignature(recoverableSignature: curvelib_swift.Signature) throws -> String {
        return try recoverableSignature.serialize()
    }

    internal static func recoverPublicKey(hash: String, recoverableSignature: curvelib_swift.Signature) throws -> PublicKey {
        return try ECDSA.recover(signature: recoverableSignature, hash: hash)
    }

    private static func randomBytes(length: Int) -> Data? {
        for _ in 0 ... 1024 {
            var data = Data(repeating: 0, count: length)
            let result = data.withUnsafeMutableBytes { mutableRBBytes -> Int32? in
                if let mutableRBytes = mutableRBBytes.baseAddress, mutableRBBytes.count > 0 {
                    let mutableBytes = mutableRBytes.assumingMemoryBound(to: UInt8.self)
                    return SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
                } else {
                    return nil
                }
            }
            if let res = result, res == errSecSuccess {
                return data
            } else {
                continue
            }
        }
        return nil
    }

    internal static func recoverableSign(hash: String, privateKey: String) throws -> curvelib_swift.Signature {
        let sk = try SecretKey(hex: privateKey)
        return try ECDSA.sign_recoverable(key: sk, hash: hash)
    }

    public static func signForRecovery(hash: String, privateKey: SecretKey) throws -> curvelib_swift.Signature {
        return try ECDSA.sign_recoverable(key: privateKey, hash: hash)
    }

    static func parsePublicKey(serializedKey: String) throws -> PublicKey {
        return try PublicKey(hex: serializedKey)
    }
    
    public static func serializePublicKey(publicKey: PublicKey, compressed: Bool = false) throws -> String {
        return try publicKey.serialize(compressed: compressed)
    }

    public static func combineSerializedPublicKeys(keys: PublicKeyCollection, outputCompressed: Bool = false) throws -> String {
        let combined = try PublicKey.combine(collection: keys)
        return try combined.serialize(compressed: outputCompressed)
    }
}
