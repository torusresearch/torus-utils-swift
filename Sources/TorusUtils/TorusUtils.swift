/**
 torus utils class
 Author: Shubham Rathi
 */

import Foundation
import FetchNodeDetails
import web3swift
import PromiseKit
import secp256k1
import PMKFoundation
import CryptoSwift
import BigInt


public class TorusUtils{
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
    var privateKey = ""
    
    public init(){
        
    }
    
    func getMetadata() -> Promise<BigInt>{
        return Promise<BigInt>.value(BigInt(0))
    }
    
    public func getPublicAddress(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String, isExtended: Bool) -> Promise<[String:String]>{
        
        let (tempPromise, seal) = Promise<[String:String]>.pending()
        let keyLookup = self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
        
        keyLookup.then{ lookupData -> Promise<[String: String]> in
            let error = lookupData["err"]
            
            if(error != nil){
                // Assign key to the user and return (wraped in a promise)
                return self.keyAssign(endpoints: endpoints, torusNodePubs: torusNodePubs, verifier: verifier, verifierId: verifierId).then{ data -> Promise<[String:String]> in
                    // Do keylookup again
                    return self.keyLookup(endpoints: endpoints, verifier: verifier, verifierId: verifierId)
                }.then{ data -> Promise<[String: String]> in
                    
                    return Promise<[String: String]>.value(data)
                }
            }else{
                return Promise<[String: String]>.value(lookupData)
            }
        }.done{ data in
            
            if(!isExtended){
                seal.fulfill(["address": data["address"]!])
            }else{
                seal.fulfill(data)
            }
        }.catch{err in
            print("err", err)
        }
        
        return tempPromise
        
    }
    
    
    
    public func retreiveShares(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String) -> Promise<String>{
        
        // Generate privatekey
        let privateKey = SECP256K1.generatePrivateKey()
        let publicKey = SECP256K1.privateToPublic(privateKey: privateKey!, compressed: false)?.suffix(64) // take last 64
        
        // Split key in 2 parts, X and Y
        let publicKeyHex = publicKey?.toHexString()
        let pubKeyX = publicKey?.prefix(publicKey!.count/2).toHexString()
        let pubKeyY = publicKey?.suffix(publicKey!.count/2).toHexString()
        
        // Hash the token from OAuth login
        let tokenCommitment = idToken.sha3(.keccak256)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        var nodeReturnedPubKeyX:String = ""
        var nodeReturnedPubKeyY:String = ""
        
        print(privateKey?.toHexString() as Any, publicKeyHex as Any, pubKeyX as Any, pubKeyY as Any, tokenCommitment)
        
        return Promise<String>{ seal in
            commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX!, pubKeyY: pubKeyY!, timestamp: timestamp, tokenCommitment: tokenCommitment)
                .then{ data -> Promise<[Int:[String:String]]> in
                    //print("data after commitment requrest", data)
                    return self.retreiveIndividualNodeShare(endpoints: endpoints, verifier: verifier, verifierParams: verifierParams, idToken: idToken, nodeSignatures: data)
            }.then{ data -> Promise<[Int:String]> in
                //print("data after retrieve shares", data)
                nodeReturnedPubKeyX = data[0]!["pubKeyX"]!
                nodeReturnedPubKeyY = data[0]!["pubKeyY"]!
                return self.decryptIndividualShares(shares: data, privateKey: privateKey!.toHexString())
            }.then{ data -> Promise<String> in
                //print("individual shares array", data)
                return self.lagrangeInterpolation(shares: data)
            }.done{ data in
                print("private key rebuild", data)
                
                let publicKey = SECP256K1.privateToPublic(privateKey: Data.init(hex: data) , compressed: false)?.suffix(64) // take last 64
                
                // Split key in 2 parts, X and Y
                // let publicKeyHex = publicKey?.toHexString()
                let pubKeyX = publicKey?.prefix(publicKey!.count/2).toHexString()
                let pubKeyY = publicKey?.suffix(publicKey!.count/2).toHexString()
                
                seal.fulfill(data)
                // Verify
                if( pubKeyX == nodeReturnedPubKeyX && pubKeyY == nodeReturnedPubKeyY) {
                    self.privateKey = data
                }else{
                    throw "could not derive private key"
                }
            }.catch{ err in
                // print(err)
                seal.reject(err)
            }
            
        }
        
    }
    
}
