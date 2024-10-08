import BigInt
import FetchNodeDetails
import Foundation
import OSLog
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

internal class MetadataUtils {
    public static func decryptNodeData(eciesData: EciesHexOmitCiphertext, ciphertextHex: String, privKey: String) throws -> String {
        return try EncryptionUtils.decryptNodeData(eciesData: eciesData, ciphertextHex: ciphertextHex, privKey: privKey)
    }

    public static func decrypt(privateKey: String, opts: ECIES) throws -> Data {
        return try EncryptionUtils.decrypt(privateKey: privateKey, opts: opts)
    }

    public static func encrypt(publicKey: String, msg: String) throws -> Ecies {
        return try EncryptionUtils.encrypt(publicKey: publicKey, msg: msg)
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

    public static func generateMetadataParams(serverTimeOffset: Int, message: String, privateKey: String, X: String, Y: String, keyType: TorusKeyType? = nil) throws -> MetadataParams {
        let privKey = try SecretKey(hex: privateKey)

        let timeStamp = String(BigUInt(TimeInterval(serverTimeOffset) + Date().timeIntervalSince1970), radix: 16)
        let setData: MetadataParams.SetData = .init(data: message, timestamp: timeStamp)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder
            .encode(setData)

        let hash = try KeyUtils.keccak256Data(encodedData).toHexString()
        let sigData = try ECDSA.signRecoverable(key: privKey, hash: hash).serialize()
        _ = try ECDSA.recover(signature: Signature(hex: sigData), hash: hash)
        return .init(pub_key_X: X, pub_key_Y: Y, setData: setData, signature: Data(hex: sigData).base64EncodedString(), keyType: keyType)
    }

    public static func getMetadata(legacyMetadataHost: String, params: GetMetadataParams) async throws -> BigUInt {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get")
        request.httpBody = try encoder.encode(params)
        let urlSession = URLSession(configuration: .default)
        let val = try await urlSession.data(for: request)
        let data: GetMetadataResponse = try JSONDecoder().decode(GetMetadataResponse.self, from: val.0)
        let msg: String = data.message
        let ret = BigUInt(msg, radix: 16)!
        return ret
    }

    public static func getOrSetNonce(legacyMetadataHost: String, serverTimeOffset: Int, X: String, Y: String, privateKey: String? = nil, getOnly: Bool = false, keyType: TorusKeyType? = nil) async throws -> GetOrSetNonceResult {
        var data: Data
        let msg = getOnly ? "getNonce" : "getOrSetNonce"
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        if privateKey != nil {
            let val = try generateMetadataParams(serverTimeOffset: serverTimeOffset, message: msg, privateKey: privateKey!, X: X, Y: Y)
            data = try encoder.encode(val)
        } else {
            let val = GetNonceParams(pub_key_X: X, pub_key_Y: Y, set_data: GetNonceSetDataParams(data: msg))
            data = try encoder.encode(val)
        }
        var request = try makeUrlRequest(url: "\(legacyMetadataHost)/get_or_set_nonce")
        request.httpBody = data
        let urlSession = URLSession(configuration: .default)
        let val = try await urlSession.data(for: request)

        let decoded = try JSONDecoder().decode(GetOrSetNonceResult.self, from: val.0)
        return decoded
    }

    public static func getOrSetSapphireMetadataNonce(metadataHost: String, network: TorusNetwork, X: String, Y: String, serverTimeOffset: Int? = nil, privateKey: String? = nil, getOnly: Bool = false, keyType: TorusKeyType = .secp256k1) async throws -> GetOrSetNonceResult {
        if case .sapphire = network {
            return try await getOrSetNonce(legacyMetadataHost: metadataHost, serverTimeOffset: serverTimeOffset ?? Int(trunc(Double(0 + Int(Date().timeIntervalSince1970)))), X: X, Y: Y, privateKey: privateKey, getOnly: getOnly, keyType: keyType)
        } else {
            throw TorusUtilError.metadataNonceMissing
        }
    }
}
