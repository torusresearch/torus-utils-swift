import BigInt
import FetchNodeDetails
/**
 torus utils class
 Author: Shubham Rathi
 */
import Foundation
import OSLog

import secp256k1

@available(macOSApplicationExtension 10.15, *)
var utilsLogType = OSLogType.default

@available(iOS 13, macOS 10.15, *)
open class TorusUtils: AbstractTorusUtils {
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
    private var timeout: Int = 30
    var urlSession: URLSession
    var serverTimeOffset: TimeInterval = 0
    var isNewKey = false
    var allowHost: String
    var network: EthereumNetworkFND
    var modulusValue = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
    var legacyNonce: Bool

    public init(loglevel: OSLogType = .default, urlSession: URLSession = URLSession(configuration: .default), enableOneKey: Bool = false, serverTimeOffset: TimeInterval = 0, signerHost: String = "https://signer.tor.us/api/sign", allowHost: String = "https://signer.tor.us/api/allow", network: EthereumNetworkFND = .MAINNET, legacyNonce: Bool = false) {
        self.urlSession = urlSession
        utilsLogType = loglevel

        self.allowHost = allowHost
        self.network = network
        self.serverTimeOffset = serverTimeOffset
        self.legacyNonce = legacyNonce
    }

    // TODO: keyassign func changed.. 
    public func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressResult {
        do {
                var data: KeyLookupResponse
                do {
                    data = try await keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                } catch {
                    if let keyLookupError = error as? KeyLookupError, keyLookupError == .verifierAndVerifierIdNotAssigned {
                            do {
                                _ = try await keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: network)
                                data = try await awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId, timeout: 1)
                            } catch {
                                throw TorusUtilError.configurationError
                            }
                    } else {
                        throw error
                    }
                }
                let pubKeyX = data.pubKeyX
                let pubKeyY = data.pubKeyY
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            var pubNonce: PubNonce?
            let result: GetPublicAddressResult
            if enableOneKey {
                let localNonceResult = try await getOrSetNonce(x: pubKeyX, y: pubKeyY, privateKey: nil, getOnly: !isNewKey)
                pubNonce = localNonceResult.pubNonce
                nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
                typeOfUser = .init(rawValue: localNonceResult.typeOfUser) ?? .v1
                if typeOfUser == .v1 {
                    modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    let nonce2 = BigInt(nonce).modulus(modulusValue)
                    if nonce != BigInt(0) {
                        guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                            throw TorusUtilError.decryptionFailed
                        }
                        modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                    } else {
                        modifiedPubKey = String(modifiedPubKey.suffix(128))
                    }
                } else if typeOfUser == .v2 {
                    if localNonceResult.upgraded ?? false {
                        modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                    } else {
                        guard localNonceResult.pubNonce != nil else { throw TorusUtilError.decodingFailed("No pub nonce found") }
                        modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                        let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
                        modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
                    }
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                } else {
                    throw TorusUtilError.runtime("getOrSetNonce should always return typeOfUser.")
                }
                result = .init(address: publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: pubKeyX, y: pubKeyY, metadataNonce: nonce, pubNonce: pubNonce)
            } else {
                typeOfUser = .v1
                let localNonce = try await getMetadata(dictionary: ["pub_key_X": pubKeyX, "pub_key_Y": pubKeyY])
                nonce = localNonce
                let localPubkeyX = data.pubKeyX
                let localPubkeyY = data.pubKeyY
                modifiedPubKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
                if localNonce != BigInt(0) {
                    let nonce2 = BigInt(localNonce).modulus(modulusValue)
                    guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                        throw TorusUtilError.decryptionFailed
                    }
                    modifiedPubKey = combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                } else {
                    modifiedPubKey = String(modifiedPubKey.suffix(128))
                }
                result = GetPublicAddressResult(address: publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: localPubkeyX, y: localPubkeyY, metadataNonce: nonce)
            }
            if !isExtended {
                let val = GetPublicAddressResult(address: result.address)
                return val
            } else {
                return result
            }
        } catch {
            throw error
        }
    }

    public func retrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponse {
        return try await withThrowingTaskGroup(of: RetrieveSharesResponse.self, body: { [unowned self] group in
            group.addTask { [unowned self] in
                try await handleRetrieveShares(torusNodePubs: torusNodePubs, endpoints: endpoints, verifier: verifier, verifierId: verifierId, idToken: idToken, extraParams: extraParams)
            }
            group.addTask { [unowned self] in
                // 60 second timeout for login
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 60_000_000_000))
                throw TorusUtilError.timeout
            }

            do {
                for try await val in group {
                    try Task.checkCancellation()
                    group.cancelAll()
                    return val
                }
            } catch {
                group.cancelAll()
                throw error
            }
            throw TorusUtilError.timeout
        })
    }

    func handleRetrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponse {
        guard
            let privateKey = generatePrivateKeyData(),
            let publicKey = SECP256K1.privateToPublic(privateKey: privateKey)?.subdata(in: 1 ..< 65)
        else {
            throw TorusUtilError.runtime("Unable to generate SECP256K1 keypair.")
        }

        // Split key in 2 parts, X and Y
        // let publicKeyHex = publicKey.toHexString()
        let pubKeyX = publicKey.prefix(publicKey.count / 2).toHexString().addLeading0sForLength64()
        let pubKeyY = publicKey.suffix(publicKey.count / 2).toHexString().addLeading0sForLength64()

        // Hash the token from OAuth login

        let timestamp = String(Int(getTimestamp()))
        let hashedToken = idToken.sha3(.keccak256)

        var publicAddress: String = ""
        var lookupPubkeyX: String = ""
        var lookupPubkeyY: String = ""
        var pk: String = ""
        do {
            let getPublicAddressData = try await getPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, isExtended: true)
            publicAddress = getPublicAddressData.address
            guard
                let localPubkeyX = getPublicAddressData.x?.addLeading0sForLength64(),
                let localPubkeyY = getPublicAddressData.y?.addLeading0sForLength64()
            else { throw TorusUtilError.runtime("Empty pubkey returned from getPublicAddress.") }
            lookupPubkeyX = localPubkeyX
            lookupPubkeyY = localPubkeyY
            let commitmentRequestData = try await commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
            os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, commitmentRequestData)
            let (x, y, key) = try await retrieveDecryptAndReconstruct(endpoints: endpoints, extraParams: extraParams, verifier: verifier, tokenCommitment: idToken, nodeSignatures: commitmentRequestData, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.toHexString())
            if enableOneKey {
                let result = try await getOrSetNonce(x: x, y: y, privateKey: key, getOnly: true)
                let nonce = BigUInt(result.nonce ?? "0", radix: 16) ?? 0
                if nonce != BigInt(0) {
                    let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                    let newKey = tempNewKey.modulus(modulusValue)
                    os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                    pk = BigUInt(newKey).serialize().suffix(64).toHexString()
                } else {
                    pk = key
                }
            } else {
                let nonce = try await getMetadata(dictionary: ["pub_key_X": x, "pub_key_Y": y])
                if nonce != BigInt(0) {
                    let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                    let newKey = tempNewKey.modulus(modulusValue)
                    os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                    pk = BigUInt(newKey).serialize().suffix(64).toHexString()
                } else {
                    pk = key
                }
            }
            return RetrieveSharesResponse(publicKey: publicAddress, privateKey: pk)
        } catch {
            os_log("Error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }
    }

    open func generatePrivateKeyData() -> Data? {
        return Data.randomOfLength(32)
    }

    open func getTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    // TODO: importPrivateKey
    
    
}
