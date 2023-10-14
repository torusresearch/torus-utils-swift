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

    private static func privateKeyToPublicKey(privateKey: Data) -> secp256k1_pubkey? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        if privateKey.count != 32 { return nil }
        var publicKey = secp256k1_pubkey()
        let result = privateKey.withUnsafeBytes { (pkRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = pkRawBufferPointer.baseAddress, pkRawBufferPointer.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = withUnsafeMutablePointer(to: &publicKey) {
                    secp256k1_ec_pubkey_create(context!, $0, privateKeyPointer)
                }
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return publicKey
    }

    // TODO: Translate below functions to secp256k1 objects and methods.

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

    public static func verifyPrivateKey(privateKey: Data) -> Bool {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        if privateKey.count != 32 { return false }
        let result = privateKey.withUnsafeBytes { privateKeyRBPointer -> Int32? in
            if let privateKeyRPointer = privateKeyRBPointer.baseAddress, privateKeyRBPointer.count > 0 {
                let privateKeyPointer = privateKeyRPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_seckey_verify(context!, privateKeyPointer)
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res == 1 else {
            return false
        }
        return true
    }

    private static func recoverPublicKey(hash: Data, recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) -> secp256k1_pubkey? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        guard hash.count == 32 else { return nil }
        var publicKey: secp256k1_pubkey = secp256k1_pubkey()
        let result = hash.withUnsafeBytes({ (hashRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let hashRawPointer = hashRawBufferPointer.baseAddress, hashRawBufferPointer.count > 0 {
                let hashPointer = hashRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature, { (signaturePointer: UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        let res = secp256k1_ecdsa_recover(context!, pubKeyPtr,
                                                          signaturePointer, hashPointer)
                        return res
                    })
                })
            } else {
                return nil
            }
        })
        guard let res = result, res != 0 else {
            return nil
        }
        return publicKey
    }

    public static func parseSignature(signature: Data) -> secp256k1_ecdsa_recoverable_signature? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        guard signature.count == 65 else { return nil }
        var recoverableSignature: secp256k1_ecdsa_recoverable_signature = secp256k1_ecdsa_recoverable_signature()
        let serializedSignature = Data(signature[0 ..< 64])
        var v = Int32(signature[64])
        if v >= 27 && v <= 30 {
            v -= 27
        } else if v >= 31 && v <= 34 {
            v -= 31
        } else if v >= 35 && v <= 38 {
            v -= 35
        }
        let result = serializedSignature.withUnsafeBytes { (serRawBufferPtr: UnsafeRawBufferPointer) -> Int32? in
            if let serRawPtr = serRawBufferPtr.baseAddress, serRawBufferPtr.count > 0 {
                let serPtr = serRawPtr.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &recoverableSignature, { (signaturePointer: UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    let res = secp256k1_ecdsa_recoverable_signature_parse_compact(context!, signaturePointer, serPtr, v)
                    return res
                })
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return recoverableSignature
    }

    private static func serializeSignature(recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) -> Data? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        var serializedSignature = Data(repeating: 0x00, count: 64)
        var v: Int32 = 0
        let result = serializedSignature.withUnsafeMutableBytes { (serSignatureRawBufferPointer: UnsafeMutableRawBufferPointer) -> Int32? in
            if let serSignatureRawPointer = serSignatureRawBufferPointer.baseAddress, serSignatureRawBufferPointer.count > 0 {
                let serSignaturePointer = serSignatureRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature) { (signaturePointer: UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &v, { (vPtr: UnsafeMutablePointer<Int32>) -> Int32 in
                        let res = secp256k1_ecdsa_recoverable_signature_serialize_compact(context!, serSignaturePointer, vPtr, signaturePointer)
                        return res
                    })
                }
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        if v == 0 || v == 27 || v == 31 || v == 35 {
            serializedSignature.append(0x1B)
        } else if v == 1 || v == 28 || v == 32 || v == 36 {
            serializedSignature.append(0x1C)
        } else {
            return nil
        }
        return Data(serializedSignature)
    }

    public static func recoverPublicKey(hash: Data, signature: Data, compressed: Bool = false) -> Data? {
        guard hash.count == 32, signature.count == 65 else { return nil }
        guard var recoverableSignature = parseSignature(signature: signature) else { return nil }
        guard var publicKey = recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature) else { return nil }
        guard let serializedKey = serializePublicKey(publicKey: &publicKey, compressed: compressed) else { return nil }
        return serializedKey
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

    private static func recoverableSign(hash: Data, privateKey: Data, useExtraEntropy: Bool = false) -> secp256k1_ecdsa_recoverable_signature? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        if hash.count != 32 || privateKey.count != 32 {
            return nil
        }
        if !verifyPrivateKey(privateKey: privateKey) {
            return nil
        }
        var recoverableSignature: secp256k1_ecdsa_recoverable_signature = secp256k1_ecdsa_recoverable_signature()
        guard let extraEntropy = randomBytes(length: 32) else { return nil }
        let result = hash.withUnsafeBytes { hashRBPointer -> Int32? in
            if let hashRPointer = hashRBPointer.baseAddress, hashRBPointer.count > 0 {
                let hashPointer = hashRPointer.assumingMemoryBound(to: UInt8.self)
                return privateKey.withUnsafeBytes({ privateKeyRBPointer -> Int32? in
                    if let privateKeyRPointer = privateKeyRBPointer.baseAddress, privateKeyRBPointer.count > 0 {
                        let privateKeyPointer = privateKeyRPointer.assumingMemoryBound(to: UInt8.self)
                        return extraEntropy.withUnsafeBytes({ extraEntropyRBPointer -> Int32? in
                            if let extraEntropyRPointer = extraEntropyRBPointer.baseAddress, extraEntropyRBPointer.count > 0 {
                                let extraEntropyPointer = extraEntropyRPointer.assumingMemoryBound(to: UInt8.self)
                                return withUnsafeMutablePointer(to: &recoverableSignature, { (recSignaturePtr: UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                                    let res = secp256k1_ecdsa_sign_recoverable(context!, recSignaturePtr, hashPointer, privateKeyPointer, nil, useExtraEntropy ? extraEntropyPointer : nil)
                                    return res
                                })
                            } else {
                                return nil
                            }
                        })
                    } else {
                        return nil
                    }
                })
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            print("Failed to sign!")
            return nil
        }
        return recoverableSignature
    }

    public static func signForRecovery(hash: Data, privateKey: Data, useExtraEntropy: Bool = false) -> (serializedSignature: Data?, rawSignature: Data?) {
        if hash.count != 32 || privateKey.count != 32 {
            return (nil, nil)
        }
        if !verifyPrivateKey(privateKey: privateKey) {
            return (nil, nil)
        }
        for _ in 0 ... 1024 {
            guard var recoverableSignature = recoverableSign(hash: hash, privateKey: privateKey, useExtraEntropy: useExtraEntropy) else {
                continue
            }
            guard let truePublicKey = privateKeyToPublicKey(privateKey: privateKey) else { continue }
            guard let recoveredPublicKey = recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature) else { continue }
            if !constantTimeComparison(Data(toByteArray(truePublicKey.data)), Data(toByteArray(recoveredPublicKey.data))) {
                continue
            }
            guard let serializedSignature = serializeSignature(recoverableSignature: &recoverableSignature) else { continue }
            let rawSignature = Data(toByteArray(recoverableSignature))
            return (serializedSignature, rawSignature)
        }
        return (nil, nil)
    }

    private static func parsePublicKey(serializedKey: Data) -> secp256k1_pubkey? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        guard serializedKey.count == 33 || serializedKey.count == 65 else {
            return nil
        }
        let keyLen: Int = Int(serializedKey.count)
        var publicKey = secp256k1_pubkey()
        let result = serializedKey.withUnsafeBytes { (serializedKeyRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let serializedKeyRawPointer = serializedKeyRawBufferPointer.baseAddress, serializedKeyRawBufferPointer.count > 0 {
                let serializedKeyPointer = serializedKeyRawPointer.assumingMemoryBound(to: UInt8.self)

                let res = withUnsafeMutablePointer(to: &publicKey) {
                    secp256k1_ec_pubkey_parse(context!, $0, serializedKeyPointer, keyLen)
                }

                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return publicKey
    }

    public static func serializePublicKey(publicKey: inout secp256k1_pubkey, compressed: Bool = false) -> Data? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        var keyLength = compressed ? 33 : 65
        var serializedPubkey = Data(repeating: 0x00, count: keyLength)
        let result = serializedPubkey.withUnsafeMutableBytes { serializedPubkeyRawBuffPointer -> Int32? in
            if let serializedPkRawPointer = serializedPubkeyRawBuffPointer.baseAddress, serializedPubkeyRawBuffPointer.count > 0 {
                let serializedPubkeyPointer = serializedPkRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &keyLength, { (keyPtr: UnsafeMutablePointer<Int>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        let res = secp256k1_ec_pubkey_serialize(context!,
                                                                serializedPubkeyPointer,
                                                                keyPtr,
                                                                pubKeyPtr,
                                                                UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED))
                        return res
                    })
                })
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return Data(serializedPubkey)
    }

    public static func combineSerializedPublicKeys(keys: [Data], outputCompressed: Bool = false) -> Data? {
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
        let numToCombine = keys.count
        guard numToCombine >= 1 else { return nil }
        var storage = ContiguousArray<secp256k1_pubkey>()
        let arrayOfPointers = UnsafeMutablePointer<UnsafePointer<secp256k1_pubkey>?>.allocate(capacity: numToCombine)
        defer {
            arrayOfPointers.deinitialize(count: numToCombine)
            arrayOfPointers.deallocate()
        }
        for i in 0 ..< numToCombine {
            let key = keys[i]
            guard let pubkey = parsePublicKey(serializedKey: key) else { return nil }
            storage.append(pubkey)
        }
        for i in 0 ..< numToCombine {
            withUnsafePointer(to: &storage[i]) { ptr in
                arrayOfPointers.advanced(by: i).pointee = ptr
            }
        }
        let immutablePointer = UnsafePointer(arrayOfPointers)
        var publicKey: secp256k1_pubkey = secp256k1_pubkey()
        let result = withUnsafeMutablePointer(to: &publicKey) { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
            let res = secp256k1_ec_pubkey_combine(context!, pubKeyPtr, immutablePointer, numToCombine)
            return res
        }
        if result == 0 {
            return nil
        }
        let serializedKey = serializePublicKey(publicKey: &publicKey, compressed: outputCompressed)
        return serializedKey
    }
}
