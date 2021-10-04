/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import FetchNodeDetails
import web3
import PromiseKit
import secp256k1
import OSLog
import BigInt

@available(macOSApplicationExtension 10.12, *)
var utilsLogType = OSLogType.default

@available(macOS 10.12, *)
public class TorusUtils: AbstractTorusUtils{
    
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))
    
    var nodePubKeys: Array<TorusNodePub>
    
    public init(nodePubKeys: Array<TorusNodePub>, loglevel: OSLogType = .default){
        self.nodePubKeys = nodePubKeys
        utilsLogType = loglevel
    }
        
    // set pubkeys later
    public convenience init(){
        self.init(nodePubKeys: [] )
    }
    
    
    public func setTorusNodePubKeys(nodePubKeys: Array<TorusNodePub>){
        self.nodePubKeys = nodePubKeys
    }
    
//    public func setEndpoints(endpoints: Array<String>){
//        self.endpoints = endpoints
//    }
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String, isExtended: Bool) -> Promise<[String:String]>{
        let (promise, seal) = Promise<[String:String]>.pending()
        let keyLookup = self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        
        keyLookup.then{ lookupData -> Promise<[String: String]> in
            let error = lookupData["err"]
            
            if(error != nil){
                guard let errorString = error else {
                    throw TorusError.runtime("Error not supported")
                }
                
                // Only assign key in case: Verifier exists and the verifierID doesn't.
                if errorString.contains("Verifier + VerifierID has not yet been assigned") {
                    // Assign key to the user and return (wrapped in a promise)
                    return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<[String:String]> in
                        // Do keylookup again
                        return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                    }.then{ data -> Promise<[String: String]> in
                        let error = data["err"]
                        if(error != nil) {
                            throw TorusError.configurationError
                        }
                        return Promise<[String: String]>.value(data)
                    }
                }
                else{
                    throw error!
                }
                
            }else{
                return Promise<[String: String]>.value(lookupData)
            }
        }.then{ data -> Promise<(BigUInt, [String: String])> in
            guard
                let pubKeyX = data["pub_key_X"],
                let pubKeyY = data["pub_key_Y"]
            else {
                throw TorusError.decodingFailed
            }
            return self.getMetadata(dictionary: ["pub_key_X": pubKeyX, "pub_key_Y": pubKeyY]).map{ ($0, data) } // Tuple
        }.done{ nonce, data in
            var newData = data
            guard
                let localPubkeyX = newData["pub_key_X"],
                let localPubkeyY = newData["pub_key_Y"]
            else { throw TorusError.runtime("Empty pubkey returned from getMetadata.") }
            
            // Convert to BigInt for modulus
            let nonce2 = BigInt(nonce).modulus(BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!)
            if(nonce != BigInt(0)) {
                let actualPublicKey = "04" + localPubkeyX.addLeading0sForLength64() + localPubkeyY.addLeading0sForLength64()
                guard let noncePublicKey = SECP256K1.privateToPublic(privateKey: BigUInt(nonce2).serialize().addLeading0sForLength64()) else {
                    throw TorusError.decryptionFailed
                }
                let addedPublicKeys = self.combinePublicKeys(keys: [actualPublicKey, noncePublicKey.toHexString()], compressed: false)
                newData["address"] = self.publicKeyToAddress(key: addedPublicKeys)
            }
            
            if(!isExtended){
                seal.fulfill(["address": newData["address"]!])
            }else{
                seal.fulfill(newData)
            }
        }.catch{err in
            os_log("getPublicAddress: err: %s", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(err)")
            seal.reject("getPublicAddress: err: \(err)")
        }
        
        return promise
    }
    
    public func retrieveShares(endpoints : Array<String>, verifierIdentifier: String, verifierId:String, idToken: String, extraParams: Data) -> Promise<[String:String]>{
        let (promise, seal) = Promise<[String:String]>.pending()
        
        // Generate keypair
        guard
            let privateKey = self.generatePrivateKeyData(),
            let publicKey = SECP256K1.privateToPublic(privateKey: privateKey)?.subdata(in: 1..<65)
        else {
            seal.reject(TorusError.runtime("Unable to generate SECP256K1 keypair."))
            return promise
        }
        
        
        // Split key in 2 parts, X and Y
        // let publicKeyHex = publicKey.toHexString()
        let pubKeyX = publicKey.prefix(publicKey.count/2).toHexString().addLeading0sForLength64()
        let pubKeyY = publicKey.suffix(publicKey.count/2).toHexString().addLeading0sForLength64()
        
        // Hash the token from OAuth login
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let hashedToken = idToken.sha3(.keccak256)
        var publicAddress: String = ""
        var lookupPubkeyX: String = ""
        var lookupPubkeyY: String = ""
        
        // os_log("Pubkeys: %s, %s, %s, %s", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, publicKeyHex, pubKeyX, pubKeyY, hashedToken)
        
        // Reject if not resolved in 30 seconds
        after(.seconds(300)).done {
            seal.reject(TorusError.timeout)
        }
        
        getPublicAddress(endpoints: endpoints, torusNodePubs: nodePubKeys, verifier: verifierIdentifier, verifierId: verifierId, isExtended: true).then{ data -> Promise<[[String:String]]> in
            publicAddress = data["address"] ?? ""
            guard
                let localPubkeyX = data["pub_key_X"]?.addLeading0sForLength64(),
                let localPubkeyY = data["pub_key_Y"]?.addLeading0sForLength64()
            else { throw TorusError.runtime("Empty pubkey returned from getPublicAddress.") }
            lookupPubkeyX = localPubkeyX
            lookupPubkeyY = localPubkeyY
            return self.commitmentRequest(endpoints: endpoints, verifier: verifierIdentifier, pubKeyX: pubKeyX, pubKeyY: pubKeyY, timestamp: timestamp, tokenCommitment: hashedToken)
        }.then{ data -> Promise<(String, String, String)> in
            os_log("retrieveShares - data after commitment request: %@",  log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info,  data)
            
            return self.retrieveDecryptAndReconstruct(endpoints: endpoints, extraParams: extraParams, verifier: verifierIdentifier, tokenCommitment: idToken, nodeSignatures: data, verifierId: verifierId, lookupPubkeyX: lookupPubkeyX, lookupPubkeyY: lookupPubkeyY, privateKey: privateKey.toHexString())
        }.then{ x, y, key in
            return self.getMetadata(dictionary: ["pub_key_X": x, "pub_key_Y": y]).map{ ($0, key) } // Tuple
        }.done{ nonce, key in
            if(nonce != BigInt(0)) {
                let tempNewKey = BigInt(nonce) + BigInt(key, radix: 16)!
                let newKey = tempNewKey.modulus(BigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!)
                os_log("%@",  log: getTorusLogger(log: TorusUtilsLogger.core, type: .info), type: .info, newKey.description)
                seal.fulfill(["privateKey": BigUInt(newKey).serialize().suffix(64).toHexString(), "publicAddress": publicAddress])
            }
            seal.fulfill(["privateKey":key, "publicAddress": publicAddress])
        }.catch{ err in
            os_log("Error: %@",  log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, err.localizedDescription)
            seal.reject(err)
        }.finally {
            if(promise.isPending){
                os_log("Error: %@",  log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, TorusError.unableToDerive.debugDescription)
                seal.reject(TorusError.unableToDerive)
            }
        }
        
        return promise
    }
}

