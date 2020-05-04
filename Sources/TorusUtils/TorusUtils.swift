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
    
    func commitmentRequest(endpoints : Array<String>, verifier: String, pubKeyX: String, pubKeyY: String, timestamp: String, tokenCommitment: String) -> Promise<[[String:String]]>{
        
//        let (tempPromise, seal) = Promise<[[String:String]]>.pending()
        
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            let encoder = JSONEncoder()
            let rpcdata = try! encoder.encode(JSONRPCrequest(
                method: "CommitmentRequest",
                params: ["messageprefix": "mug00",
                         "tokencommitment": tokenCommitment,
                         "temppubx": pubKeyX,
                         "temppuby": pubKeyY,
                         "verifieridentifier":verifier,
                         "timestamp": timestamp]
            ))
            // print( String(data: rpcdata, encoding: .utf8)!)
            promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        
        // Array to store intermediate results
        var resultArrayStrings = Array<Any?>.init(repeating: nil, count: promisesArray.count)
        var resultArrayObjects = Array<JSONRPCresponse?>.init(repeating: nil, count: promisesArray.count)
        var isTokenCommitmentDone = false
        
        return Promise<[[String:String]]>{ seal in
            for (i, pr) in promisesArray.enumerated(){
                pr.done{ data, response in
                    // seal.fulfill([["1":"@"]])
                    let encoder = JSONEncoder()
                    let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data)
                    
                    if(decoded.error != nil) {
                        print(decoded)
                        throw "decoding error"
                    }
                    
                    // check if k+t responses are back
                    resultArrayStrings[i] = String(data: try encoder.encode(decoded), encoding: .utf8)
                    resultArrayObjects[i] = decoded
                    
                    let lookupShares = resultArrayStrings.filter{ $0 as? String != nil } // Nonnil elements
                    if(lookupShares.count >= Int(endpoints.count/4)*3+1 && !isTokenCommitmentDone){
                        print("resolving some promise")
                        isTokenCommitmentDone = true
                        
                        var nodeSignatures: [[String:String]] = []
                        for el in resultArrayObjects{
                            if(el != nil){
                                nodeSignatures.append(el?.result as! [String:String])
                            }
                        }
                        seal.fulfill(nodeSignatures)

                    }
                    else{
                        // return Promise.init(error: "LookupShares.count is \(lookupShares.count), Commitment didn't succeed with at \(i)")
                    }
                }.catch{ err in
                    seal.reject(err)
                }
            }
        }
        
    }
    
    public func retreiveShares(endpoints : Array<String>, verifier: String, verifierParams: [String: String], idToken:String){
        
        // let (tempPromise, seal) = Promise<String>.pending()
        
        // Generate pubkey-privatekey
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
        
        // print(privateKey?.toHexString() as Any, publicKeyHex as Any, pubKeyX as Any, pubKeyY as Any, tokenCommitment)
        
        commitmentRequest(endpoints: endpoints, verifier: verifier, pubKeyX: pubKeyX!, pubKeyY: pubKeyY!, timestamp: timestamp, tokenCommitment: tokenCommitment)
            .done{ data in
                print("data after commitment requrest", data)
                nodeReturnedPubKeyX = data[0]["nodepubx"]!
                nodeReturnedPubKeyY = data[0]["nodepuby"]!
                //return self.retreiveIndividualNodeShare(endpoints: endpoints, verifier: verifier, verifierParams: verifierParams, idToken: idToken, nodeSignatures: data)
        }
//        .then{ data -> Promise<[Int:String]> in
//            print("data after retrieve shares", data)
//            return self.decryptIndividualShares(shares: data, privateKey: privateKey!.toHexString())
//        }.then{ data -> Promise<String> in
//            print("individual shares array", data)
//            return self.lagrangeInterpolation(shares: data)
//        }.done{ data in
//            print("private key rebuild", data)
//
//            let publicKey = SECP256K1.privateToPublic(privateKey: Data.init(hex: data) , compressed: false)?.suffix(64) // take last 64
//
//            // Split key in 2 parts, X and Y
//            // let publicKeyHex = publicKey?.toHexString()
//            let pubKeyX = publicKey?.prefix(publicKey!.count/2).toHexString()
//            let pubKeyY = publicKey?.suffix(publicKey!.count/2).toHexString()
//
//            // Verify
//            if( pubKeyX == nodeReturnedPubKeyX && pubKeyY == nodeReturnedPubKeyY) {
//                self.privateKey = data
//            }else{
//                throw "could not derive private key"
//            }
//
            ///seal.fulfill(self.privateKey)
     //   }
    .catch{ err in
            print(err)
            // seal.reject(err)
        }
        
    }
    
}
