import BigInt
import FetchNodeDetails
import Foundation
import OSLog
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

internal class MetadataUtils {
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
        let msg = try EncryptedMessage(cipherText: opts.ciphertext, ephemeralPublicKey: PublicKey(hex: opts.ephemPublicKey), iv: opts.iv, mac: opts.mac)
        let result = try Encryption.decrypt(sk: secret, encrypted: msg)
        return result
    }

    public static func encrypt(publicKey: String, msg: String) throws -> Ecies {
        let data = Data(hex: msg)
        let curveMsg = try Encryption.encrypt(pk: PublicKey(hex: publicKey), plainText: data)
        return try .init(iv: curveMsg.iv(), ephemPublicKey: curveMsg.ephemeralPublicKey().serialize(compressed: false), ciphertext: curveMsg.chipherText(), mac: curveMsg.mac())
    }

    internal static func makeUrlRequest(url: String, httpMethod: httpMethod = .post) throws -> URLRequest {
        guard
            let url = URL(string: url)
        else {
            throw TorusUtilError.runtime("Invalid Url \(url)")
        }
        var rq = URLRequest(url: url)
        rq.httpMethod = httpMethod.name
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        return rq
    }

    public static func generateMetadataParams(serverTimeOffset: Int, message: String, privateKey: String) throws -> MetadataParams {
        let privKey = try SecretKey(hex: privateKey)
        let publicKey = try privKey.toPublic().serialize(compressed: false)

        let timeStamp = String(BigUInt(TimeInterval(serverTimeOffset) + Date().timeIntervalSince1970), radix: 16)
        let setData: MetadataParams.SetData = .init(data: message, timestamp: timeStamp)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder
            .encode(setData)

        let hash = try KeyUtils.keccak256Data(encodedData).toHexString()
        let sigData = try ECDSA.signRecoverable(key: privKey, hash: hash).serialize()
        _ = try ECDSA.recover(signature: Signature(hex: sigData), hash: hash)
        let (X, Y) = try KeyUtils.getPublicKeyCoords(pubKey: publicKey)
        return .init(pub_key_X: X, pub_key_Y: Y, setData: setData, signature: Data(hex: sigData).base64EncodedString())
    }

    public static func getMetadata(legacyMetadataHost: String, dictionary: [String: String]) async throws -> BigUInt {
        let encoded = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])

        var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get")
        request.httpBody = encoded
        let urlSession = URLSession(configuration: .default)
        let val = try await urlSession.data(for: request)
        let data = try JSONSerialization.jsonObject(with: val.0) as? [String: Any] ?? [:]
        os_log("getMetadata: %@", log: getTorusLogger(log: TorusUtilsLogger.network, type: .info), type: .info, data)
        guard
            let msg: String = data["message"] as? String,
            let ret = BigUInt(msg, radix: 16)
        else {
            throw TorusUtilError.decodingFailed("Message value not correct or nil in \(data)")
        }
        return ret
    }

    public static func getOrSetNonce(legacyMetadataHost: String, serverTimeOffset: Int, X: String, Y: String, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResult {
        var data: Data
        let msg = getOnly ? "getNonce" : "getOrSetNonce"
        if privateKey != nil {
            let val = try generateMetadataParams(serverTimeOffset: serverTimeOffset, message: msg, privateKey: privateKey!)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            data = try encoder.encode(val)
        } else {
            let dict: [String: Any] = ["pub_key_X": X, "pub_key_Y": Y, "set_data": ["data": msg]]
            data = try JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
        }
        var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get_or_set_nonce")
        request.httpBody = data
        let urlSession = URLSession(configuration: .default)
        let val = try await urlSession.data(for: request)
        let decoded = try JSONDecoder().decode(GetOrSetNonceResult.self, from: val.0)
        return decoded
    }

    public static func getOrSetSapphireMetadataNonce(legacyMetadataHost: String, network: TorusNetwork, X: String, Y: String, serverTimeOffset: Int? = nil, privateKey: String? = nil, getOnly: Bool = false) async throws -> GetOrSetNonceResult {
        if case .sapphire = network {
            return try await getOrSetNonce(legacyMetadataHost: legacyMetadataHost, serverTimeOffset: serverTimeOffset ?? Int(trunc(Double((0) + Int(Date().timeIntervalSince1970)))), X: X, Y: Y, privateKey: privateKey, getOnly: getOnly)
        } else {
            throw TorusUtilError.metadataNonceMissing
        }
    }
}
