import BigInt
import Foundation
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

enum TorusKeyType: String, Equatable, Hashable, Codable {
    case secp256k1
}

public class KeyUtils {
    public static func keccak256Data(_ input: String) throws -> String {
        guard let data = input.data(using: .utf8) else {
            SentryUtils.captureException("\(TorusUtilError.invalidInput) for client id: \(TorusUtils.getClientId())")
            throw TorusUtilError.invalidInput
        }
        return try keccak256(data: data).toHexString()
    }

    public static func keccak256Data(_ data: Data) throws -> Data {
        return try keccak256(data: data)
    }

    public static func randomNonce() throws -> String {
        return try generateSecret()
    }

    public static func generateSecret() throws -> String {
        let secret = SecretKey()
        return try secret.serialize().addLeading0sForLength64()
    }

    internal static func getOrderOfCurve() -> BigInt {
        let orderHex = CURVE_N
        let order = BigInt(orderHex, radix: 16)!
        return order
    }

    internal static func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) throws -> String {
        let publicKeyHex = KeyUtils.getPublicKeyFromCoords(pubKeyX: publicKeyX, pubKeyY: publicKeyY, prefixed: false)
        let publicKeyData = Data(hex: publicKeyHex)
        let ethAddrData = try keccak256Data(publicKeyData).suffix(20)
        let ethAddrlower = ethAddrData.toHexString().addHexPrefix().lowercased()
        return try toChecksumAddress(hexAddress: ethAddrlower)
    }

    internal static func toChecksumAddress(hexAddress: String) throws -> String {
        let lowerCaseAddress = hexAddress.stripHexPrefix().lowercased()
        let arr = Array(lowerCaseAddress)
        let hash = try keccak256Data(lowerCaseAddress.data(using: .utf8) ?? Data()).toHexString()

        var result = String()
        for i in 0 ... lowerCaseAddress.count - 1 {
            let iIndex = hash.index(hash.startIndex, offsetBy: i)
            if let val = hash[iIndex].hexDigitValue, val >= 8 {
                result.append(arr[i].uppercased())
            } else {
                result.append(arr[i])
            }
        }
        return result.addHexPrefix()
    }

    public static func getPublicKeyCoords(pubKey: String) throws -> (String, String) {
        var publicKeyUnprefixed = pubKey
        if publicKeyUnprefixed.count > 128 {
            publicKeyUnprefixed = publicKeyUnprefixed.strip04Prefix()
        }
        

        if (publicKeyUnprefixed.count <= 128) {
            publicKeyUnprefixed = publicKeyUnprefixed.addLeading0sForLength128()
        } else {
            SentryUtils.captureException("\(TorusUtilError.invalidPubKeySize) for client id: \(TorusUtils.getClientId())")
            throw TorusUtilError.invalidPubKeySize
        }

        return (String(publicKeyUnprefixed.prefix(64)), String(publicKeyUnprefixed.suffix(64)))
    }

    public static func getPublicKeyFromCoords(pubKeyX: String, pubKeyY: String, prefixed: Bool = true) -> String {
        let X = pubKeyX.addLeading0sForLength64()
        let Y = pubKeyY.addLeading0sForLength64()

        return prefixed ? (X + Y).add04PrefixUnchecked() : X + Y
    }

    internal static func combinePublicKeys(keys: [String], compressed: Bool = false) throws -> String {
        var collection: [PublicKey] = []

        for item in keys {
            try collection.append(PublicKey(hex: item))
        }

        return try combinePublicKeys(keys: collection, compressed: compressed)
    }

    internal static func combinePublicKeys(keys: [PublicKey], compressed: Bool = false) throws -> String {
        let collection = PublicKeyCollection()
        for item in keys {
            try collection.insert(key: item)
        }

        let added = try PublicKey.combine(collection: collection).serialize(compressed: compressed)
        return added
    }

    internal static func generateKeyData(privateKey: String) throws -> PrivateKeyData {
        let scalar = BigInt(privateKey, radix: 16)!

        let randomNonce = BigInt(try SecretKey().serialize().addLeading0sForLength64(), radix: 16)!

        let oAuthKey = (scalar - randomNonce).modulus(KeyUtils.getOrderOfCurve())

        let oAuthPubKeyString = try SecretKey(hex: oAuthKey.magnitude.serialize().hexString.addLeading0sForLength64()).toPublic().serialize(compressed: false)

        let finalUserPubKey = try SecretKey(hex: privateKey).toPublic().serialize(compressed: false)

        return PrivateKeyData(
            oAuthKey: oAuthKey.magnitude.serialize().hexString.addLeading0sForLength64(),
            oAuthPubKey: oAuthPubKeyString,
            nonce: randomNonce.magnitude.serialize().hexString.addLeading0sForLength64(),
            signingKey: oAuthKey.magnitude.serialize().hexString.addLeading0sForLength64(),
            signingPubKey: oAuthPubKeyString,
            finalKey: privateKey,
            finalPubKey: finalUserPubKey
        )
    }

    private static func generateNonceMetadataParams(operation: String, privateKey: BigInt, nonce: BigInt?, serverTimeOffset: Int?) throws -> NonceMetadataParams {
        let privKey = try SecretKey(hex: privateKey.magnitude.serialize().hexString.addLeading0sForLength64())

        var setData = SetNonceData(operation: operation, timestamp: String(BigUInt(trunc(Double((serverTimeOffset ?? 0) + Int(Date().timeIntervalSince1970)))), radix: 16))

        if nonce != nil {
            setData.data = nonce!.magnitude.serialize().hexString.addLeading0sForLength64()
        }

        let publicKey = try privKey.toPublic().serialize(compressed: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder
            .encode(setData)

        let hash = try KeyUtils.keccak256Data(encodedData).toHexString()
        let sigData = try ECDSA.signRecoverable(key: privKey, hash: hash).serialize()
        _ = try ECDSA.recover(signature: Signature(hex: sigData), hash: hash)
        let (pubKeyX, pubKeyY) = try KeyUtils.getPublicKeyCoords(pubKey: publicKey)
        return .init(pub_key_X: pubKeyX, pub_key_Y: pubKeyY, setData: setData, encodedData: encodedData.base64EncodedString(), signature: Data(hex: sigData).base64EncodedString())
    }

    internal static func generateShares(keyType: TorusKeyType = .secp256k1, serverTimeOffset: Int, nodeIndexes: [BigUInt], nodePubKeys: [INodePub], privateKey: String) throws -> [ImportedShare] {
        if keyType != TorusKeyType.secp256k1 {
            SentryUtils.captureException("Unsupported key type for client id: \(TorusUtils.getClientId())")
            throw TorusUtilError.runtime("Unsupported key type")
        }

        let keyData = try generateKeyData(privateKey: privateKey)

        let threshold = Int(trunc(Double((nodePubKeys.count / 2) + 1)))
        let degree = threshold - 1
        let nodeIndexesBN = nodeIndexes.map({ BigInt($0) })

        let poly = try Lagrange.generateRandomPolynomial(degree: degree, secret: BigInt(keyData.oAuthKey, radix: 16))
        let shares = poly.generateShares(shareIndexes: nodeIndexesBN)
        let nonceParams = try KeyUtils.generateNonceMetadataParams(operation: "getOrSetNonce", privateKey: BigInt(keyData.signingKey, radix: 16)!, nonce: BigInt(keyData.nonce, radix: 16), serverTimeOffset: serverTimeOffset)

        var encShares: [Ecies] = []
        for i in 0 ..< nodePubKeys.count {
            let shareInfo: Share = shares[nodeIndexes[i].magnitude.serialize().hexString.addLeading0sForLength64()]!

            let nodePub = KeyUtils.getPublicKeyFromCoords(pubKeyX: nodePubKeys[i].X, pubKeyY: nodePubKeys[i].Y)
            let nodePubKey = try PublicKey(hex: nodePub).serialize(compressed: true)
            let encrypted = try MetadataUtils.encrypt(publicKey: nodePubKey, msg: shareInfo.share.magnitude.serialize().hexString.addLeading0sForLength64())
            encShares.append(encrypted)
        }

        var sharesData: [ImportedShare] = []
        for i in 0 ..< nodePubKeys.count {
            let encrypted = encShares[i]
            let (oAuthPubX, oAuthPubY) = try getPublicKeyCoords(pubKey: try PublicKey(hex: keyData.oAuthPubKey).serialize(compressed: false))
            let (signingPubX, signingPubY) = try getPublicKeyCoords(pubKey: try PublicKey(hex: keyData.signingPubKey).serialize(compressed: false))
            let (finalPubX, finalPubY) = try getPublicKeyCoords(pubKey: try PublicKey(hex: keyData.finalPubKey).serialize(compressed: false))
            let finalPoint = try Point(x: finalPubX, y: finalPubY)
            let importShare = ImportedShare(
                oauth_pub_key_x: oAuthPubX,
                oauth_pub_key_y: oAuthPubY,
                final_user_point: finalPoint,
                signing_pub_key_x: signingPubX,
                signing_pub_key_y: signingPubY,
                encryptedShare: encrypted.ciphertext,
                encryptedShareMetadata: EciesHexOmitCiphertext(from: encrypted),
                node_index: Int(nodeIndexes[i].magnitude.serialize().hexString.addLeading0sForLength64(), radix: 16)!,
                nonce_data: nonceParams.encodedData,
                nonce_signature: nonceParams.signature)
            sharesData.append(importShare)
        }

        return sharesData
    }
}
