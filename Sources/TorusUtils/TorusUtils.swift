import BigInt
import FetchNodeDetails
/**
 torus utils class
 Author: Shubham Rathi
 */
import Foundation
import OSLog
import PromiseKit
import secp256k1

@available(macOSApplicationExtension 10.12, *)
var utilsLogType = OSLogType.default

@available(macOS 10.12, *)
open class TorusUtils: AbstractTorusUtils {
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))

    var urlSession: URLSession
    var enableOneKey: Bool
    var serverTimeOffset: TimeInterval = 0
    var isNewKey = false
    var metaDataHost: String
    var signerHost: String
    var allowHost: String
    var network: EthereumNetworkFND
    var modulusValue = BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!

    public init(loglevel: OSLogType = .default, urlSession: URLSession = URLSession.shared, enableOneKey: Bool = false, serverTimeOffset: TimeInterval = 0, metaDataHost: String = "https://metadata.tor.us", signerHost: String = "https://signer.tor.us/api/sign", allowHost: String = "https://signer.tor.us/api/allow", network: EthereumNetworkFND = .MAINNET) {
        self.urlSession = urlSession
        utilsLogType = loglevel
        self.metaDataHost = metaDataHost
        self.enableOneKey = enableOneKey
        self.signerHost = signerHost
        self.allowHost = allowHost
        self.network = network
        self.serverTimeOffset = serverTimeOffset
    }

    public func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<GetPublicAddressModel> {
        let (promise, seal) = Promise<GetPublicAddressModel>.pending()
        _ = keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId).then { [self] lookupData -> Promise<[String: String]> in
            let error = lookupData["err"]

            if error != nil, let errorString = error {
                if errorString.contains("Verifier not supported") {
                    throw TorusUtilError.runtime("Verifier not supported. Check if you: \n1. Are on the right network (Torus testnet/mainnet) \n2. Have setup a verifier on dashboard.web3auth.io?")
                }
                // Only assign key in case: Verifier exists and the verifierID doesn't.
                else if errorString.contains("Verifier + VerifierID has not yet been assigned") {
                    // Assign key to the user and return (wrapped in a promise)
                    return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId, signerHost: signerHost, network: self.network).then { _ -> Promise<[String: String]> in
                        // Do keylookup again
                        self.awaitKeyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                    }.then { data -> Promise<[String: String]> in
                        let error = data["err"]
                        if error != nil {
                            throw TorusUtilError.configurationError
                        }
                        return Promise<[String: String]>.value(data)
                    }
                } else {
                    throw error!
                }

            } else {
                return Promise<[String: String]>.value(lookupData)
            }
        }.then { data -> Promise<GetPublicAddressModel> in
            guard
                let pubKeyX = data["pub_key_X"],
                let pubKeyY = data["pub_key_Y"]
            else {
                throw TorusUtilError.runtime("pub_key_X and pub_key_Y missing from \(data)")
            }
            var modifiedPubKey: String = ""
            var nonce: BigUInt = 0
            var typeOfUser: TypeOfUser = .v1
            var pubNonce: PubNonce?
            if self.enableOneKey {
                _ = self.getOrSetNonce(x: pubKeyX, y: pubKeyY, privateKey: nil, getOnly: !self.isNewKey).done { localNonceResult in
                    pubNonce = localNonceResult.pubNonce
                    nonce = BigUInt(localNonceResult.nonce ?? "0") ?? 0
                    typeOfUser = .init(rawValue: localNonceResult.typeOfUser) ?? .v1
                    if typeOfUser == .v1 {
                        modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                        let nonce2 = BigInt(nonce).modulus(self.modulusValue)
                        if nonce != BigInt(0) {
                            guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                                throw TorusUtilError.decryptionFailed
                            }
                            modifiedPubKey = self.combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                        } else {
                            modifiedPubKey = String(modifiedPubKey.suffix(128))
                        }
                    } else if typeOfUser == .v2 {
                        if localNonceResult.upgraded ?? false {
                            modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + "04" + pubKeyY.addLeading0sForLength64()
                        } else {
                            guard localNonceResult.pubNonce != nil else { throw TorusUtilError.decodingFailed("No pub nonce found") }
                            modifiedPubKey = "04" + pubKeyX.addLeading0sForLength64() + pubKeyY.addLeading0sForLength64()
                            let ecpubKeys = "04" + localNonceResult.pubNonce!.x.addLeading0sForLength64() + localNonceResult.pubNonce!.y.addLeading0sForLength64()
                            modifiedPubKey = self.combinePublicKeys(keys: [modifiedPubKey, ecpubKeys], compressed: false)
                        }
                        modifiedPubKey = String(modifiedPubKey.suffix(128))
                    } else {
                        seal.reject(TorusUtilError.runtime("getOrSetNonce should always return typeOfUser."))
                    }
                    seal.fulfill(.init(address: self.publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: pubKeyX, y: pubKeyY, metadataNonce: nonce, pubNonce: pubNonce))
                }
            } else {
                typeOfUser = .v1
                _ = self.getMetadata(dictionary: ["pub_key_X": pubKeyX, "pub_key_Y": pubKeyY]).map { ($0, data) }.done { localNonce, data in
                    nonce = localNonce
                    guard
                        let localPubkeyX = data["pub_key_X"],
                        let localPubkeyY = data["pub_key_Y"]
                    else { throw TorusUtilError.runtime("Empty pubkey returned from getMetadata.") }
                    modifiedPubKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
                    if localNonce != BigInt(0) {
                        let nonce2 = BigInt(localNonce).modulus(self.modulusValue)
                        guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                            throw TorusUtilError.decryptionFailed
                        }
                        modifiedPubKey = self.combinePublicKeys(keys: [modifiedPubKey, noncePublicKey.toHexString()], compressed: false)
                    } else {
                        modifiedPubKey = String(modifiedPubKey.suffix(128))
                    }
                    seal.fulfill(GetPublicAddressModel(address: self.publicKeyToAddress(key: modifiedPubKey), typeOfUser: typeOfUser, x: localPubkeyX, y: localPubkeyY, metadataNonce: nonce))
                }
            }
            return promise
        }
        .done({ result in
            if !isExtended {
                let val = GetPublicAddressModel(address: result.address)
                seal.fulfill(val)
            } else {
                seal.fulfill(result)
            }
        })
        .catch({ error in
            seal.reject(error)
        })

        return promise
    }

    public func retrieveShares(torusNodePubs: Array<TorusNodePubModel>, endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String: String]> {
        let (promise, seal) = Promise<[String: String]>.pending()

        // Generate keypair
        guard
            let privateKey = generatePrivateKeyData(),
            let publicKey = SECP256K1.privateToPublic(privateKey: privateKey)?.subdata(in: 1 ..< 65)
        else {
            seal.reject(TorusUtilError.runtime("Unable to generate SECP256K1 keypair."))
            return promise
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

        // os_log("Pubkeys: %s, %s, %s, %s", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, publicKeyHex, pubKeyX, pubKeyY, hashedToken)

        // Reject if not resolved in 30 seconds
        after(.seconds(300)).done {
            seal.reject(TorusUtilError.timeout)
        }

        getPublicAddress(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifierIdentifier, verifierId: verifierId, isExtended: true).then { data -> Promise<[[String: String]]> in
            publicAddress = data.address
            guard
                let localPubkeyX = data.x?.addLeading0sForLength64(),
                let localPubkeyY = data.y?.addLeading0sForLength64()
            else { throw TorusUtilError.runtime("Empty pubkey returned from getPublicAddress.") }
            lookupPubkeyX = localPubkeyX
            lookupPubkeyY = localPubkeyY
            return self.commitmentRequest(endpoints: endpoints, verifier: verifierIdentifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
        }.then { data -> Promise<(String, String, String)> in
            os_log("retrieveShares - data after commitment request: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, data)
            return self.retrieveDecryptAndReconstruct(endpoints: endpoints, extraParams: extraParams, verifier: verifierIdentifier, tokenCommitment: idToken, nodeSignatures: data, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.toHexString())
        }.then { x, y, key -> Promise<String> in
            let (promise, seal) = Promise<String>.pending()
            if self.enableOneKey {
                _ = self.getOrSetNonce(x: x, y: y, privateKey: key, getOnly: true).done { result in
                    let nonce = BigUInt(result.nonce ?? "0", radix: 16) ?? 0
                    if nonce != BigInt(0) {
                        let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                        let newKey = tempNewKey.modulus(self.modulusValue)
                        os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                        seal.fulfill(BigUInt(newKey).serialize().suffix(64).toHexString())
                    } else {
                        seal.fulfill(key)
                    }
                }
            } else {
                _ = self.getMetadata(dictionary: ["pub_key_X": x, "pub_key_Y": y]).map { ($0, key) }
                    .done { nonce, key in
                        if nonce != BigInt(0) {
                            let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                            let newKey = tempNewKey.modulus(self.modulusValue)
                            os_log("%@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                            seal.fulfill(BigUInt(newKey).serialize().suffix(64).toHexString())
                        } else {
                            seal.fulfill(key)
                        }
                    }
            }
            return promise
        }
        .done({ privateKey in
            seal.fulfill(["privateKey": privateKey, "publicAddress": publicAddress])
        })
        .catch { err in
            os_log("Error: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
            seal.reject(err)
        }
        return promise
    }

    open func generatePrivateKeyData() -> Data? {
        return Data.randomOfLength(32)
    }

    open func getTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}
