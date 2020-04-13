//
//  File.swift
//  
//
//  Created by Shubham on 25/3/20.
//

import Foundation
import fetch_node_details
import PromiseKit
import secp256k1
import PMKFoundation

extension Torus {
    
    func makeUrlRequest(url: String) throws -> URLRequest {
        var rq = URLRequest(url: URL(string: url)!)
        rq.httpMethod = "POST"
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        // rq.httpBody = try JSONEncoder().encode(obj)
        return rq
    }
    
    func thresholdSame<T:Hashable>(arr: Array<T>, threshold: Int) -> T?{
        // uprint(threshold)
        var hashmap = [T:Int]()
        for (_, value) in arr.enumerated(){
            if((hashmap[value]) != nil) {hashmap[value]! += 1}
            else { hashmap[value] = 1 }
            if (hashmap[value] == threshold){
                return value
            }
            //print(hashmap)
        }
        return nil
    }
    
    func ecdh(pubKey: secp256k1_pubkey, privateKey: Data) -> secp256k1_pubkey? {
        var pubKey2 = pubKey // Pointer takes variable
        if (privateKey.count != 32) {return nil}
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_pubkey_tweak_mul(Torus.context!, UnsafeMutablePointer<secp256k1_pubkey>(&pubKey2), privateKeyPointer)
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return pubKey2
    }
    
    public func keyLookup(endpoints : Array<String>, verifier : String, verifierId : String) -> Promise<[String:String]>{
        
        let (tempPromise, seal) = Promise<[String:String]>.pending()
        
        // Create Array of URLRequest Promises
        var promisesArray = Array<Promise<(data: Data, response: URLResponse)> >()
        for el in endpoints {
            let rq = try! self.makeUrlRequest(url: el);
            let encoder = JSONEncoder()
            let rpcdata = try! encoder.encode(JSONRPCrequest(method: "VerifierLookupRequest", params: ["verifier":verifier, "verifier_id":verifierId]))
            //print( String(data: rpcdata, encoding: .utf8)!)
            promisesArray.append(URLSession.shared.uploadTask(.promise, with: rq, from: rpcdata))
        }
        
        var resultArray = Array<[String:String]?>.init(repeating: nil, count: promisesArray.count)
        for (i, pr) in promisesArray.enumerated() {
            pr.done{ data, response in
                //print("keyLookup", String(data: data, encoding: .utf8))
                let decoder = try? JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                //print(decoder)
                let result = decoder!.result
                var decodedResult = result as! [String:[[String:String]]]
                let keys = decodedResult["keys"]![0] as [String:String]
                // print(keys)
//                let encoder = JSONEncoder()
//
//                if #available(OSX 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
//                    encoder.outputFormatting = .sortedKeys
//                } else {
//                    // Fallback on earlier versions
//                    seal.reject("sorting keys unavailable")
//                }
//
                // Check if 5 responses are in
                resultArray[i] = keys // Encode the result and error into string and push to array
                // print(resultArray[i])
                
                let lookupShares = resultArray.filter{ $0 != nil } // Nonnil elements
                let keyResult = self.thresholdSame(arr: lookupShares, threshold: Int(endpoints.count/2)+1) // Check if threshold is satisfied
                // let errorResult = self.thresholdSame(arr: lookupShares.map{$0 as! String}, threshold: Int(endpoints.count/2)+1)
                print("threshold result", keyResult)
                
                if(keyResult != nil)  { seal.fulfill(keyResult!!) }
            }.catch{error in
                print(error)
//                if(i+1 == promisesArray.count){
//                    seal.reject(error)
//                }
            }
        }
        return tempPromise
    }
    
    public func keyAssign(endpoints : Array<String>, torusNodePubs : Array<TorusNodePub>, verifier : String, verifierId : String) -> Promise<JSONRPCresponse> {
        
        let (tempPromise, resolver) = Promise<JSONRPCresponse>.pending()
        
        var newEndpoints = endpoints
        newEndpoints.shuffle()
        print("newEndpoints", newEndpoints)
        
        let serialQueue = DispatchQueue(label: "keyassign.serial.queue")
        let semaphore = DispatchSemaphore(value: 1)
        
        for (i, endpoint) in endpoints.enumerated() {
            serialQueue.async {
                
                // Wait for the signal
                semaphore.wait()
                
                let encoder = JSONEncoder()
                let SignerObject = JSONRPCrequest(method: "KeyAssign", params: ["verifier":verifier, "verifier_id":verifierId])
                // print(SignerObject)
                let rpcdata = try! encoder.encode(SignerObject)
                // print("rpcdata", String(data: rpcdata, encoding: .utf8))
                var request = try! self.makeUrlRequest(url:  "https://signer.tor.us/api/sign")
                request.addValue(torusNodePubs[i].getX(), forHTTPHeaderField: "pubKeyX")
                request.addValue(torusNodePubs[i].getY(), forHTTPHeaderField: "pubKeyY")
                
                firstly {
                    URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
                }.then{ data, response -> Promise<(data: Data, response: URLResponse)> in
                    // print("repsonse from signer", String(data: data, encoding: .utf8))
                    // Combine jsonData and rpcData
                    let jsonData = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    var request = try self.makeUrlRequest(url: endpoint)
                    
                    request.addValue(jsonData["torus-timestamp"] as! String, forHTTPHeaderField: "torus-timestamp")
                    request.addValue(jsonData["torus-nonce"] as! String, forHTTPHeaderField: "torus-nonce")
                    request.addValue(jsonData["torus-signature"] as! String, forHTTPHeaderField: "torus-signature")
                    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    // print(request.allHTTPHeaderFields)
                    return URLSession.shared.uploadTask(.promise, with: request, from: rpcdata)
                }.done{ data, response in
                    let decodedData = try! JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                    // print("response from node", String(data: data, encoding: .utf8))
                    // print(String(data: data, encoding: .utf8))
                    resolver.fulfill(decodedData)
                    
                    // Signal to start again
                    semaphore.signal()
                }.catch{ err in
                    // Reject only if reached the last point
                    if(i+1==endpoint.count) {
                        resolver.reject(err)
                    }
                    // Signal to start again
                    semaphore.signal()
                }
                
            }
        }
        return tempPromise
        
    }
    
    func privateKeyToPublicKey4(privateKey: Data) -> secp256k1_pubkey? {
        if (privateKey.count != 32) {return nil}
        var publicKey = secp256k1_pubkey()
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_pubkey_create(Torus.context!, UnsafeMutablePointer<secp256k1_pubkey>(&publicKey), privateKeyPointer)
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
    
    func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }
    
    func array32toTuple(_ arr: Array<UInt8>) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8){
        return (arr[0] as UInt8, arr[1] as UInt8, arr[2] as UInt8, arr[3] as UInt8, arr[4] as UInt8, arr[5] as UInt8, arr[6] as UInt8, arr[7] as UInt8, arr[8] as UInt8, arr[9] as UInt8, arr[10] as UInt8, arr[11] as UInt8, arr[12] as UInt8, arr[13] as UInt8, arr[14] as UInt8, arr[15] as UInt8, arr[16] as UInt8, arr[17] as UInt8, arr[18] as UInt8, arr[19] as UInt8, arr[20] as UInt8, arr[21] as UInt8, arr[22] as UInt8, arr[23] as UInt8, arr[24] as UInt8, arr[25] as UInt8, arr[26] as UInt8, arr[27] as UInt8, arr[28] as UInt8, arr[29] as UInt8, arr[30] as UInt8, arr[31] as UInt8, arr[32] as UInt8, arr[33] as UInt8, arr[34] as UInt8, arr[35] as UInt8, arr[36] as UInt8, arr[37] as UInt8, arr[38] as UInt8, arr[39] as UInt8, arr[40] as UInt8, arr[41] as UInt8, arr[42] as UInt8, arr[43] as UInt8, arr[44] as UInt8, arr[45] as UInt8, arr[46] as UInt8, arr[47] as UInt8, arr[48] as UInt8, arr[49] as UInt8, arr[50] as UInt8, arr[51] as UInt8, arr[52] as UInt8, arr[53] as UInt8, arr[54] as UInt8, arr[55] as UInt8, arr[56] as UInt8, arr[57] as UInt8, arr[58] as UInt8, arr[59] as UInt8, arr[60] as UInt8, arr[61] as UInt8, arr[62] as UInt8, arr[63] as UInt8)
    }
    
}

// Necessary for decryption

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        //print(startIndex, count)
        return (0..<count/2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            // print(startIndex, endIndex)
            return UInt8(self[startIndex...endIndex], radix: 16)
        }
    }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}

extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}

extension String {
    func fromBase64() -> String? {
            guard let data = Data(base64Encoded: self) else {
                    return nil
            }
            return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
            return Data(self.utf8).base64EncodedString()
    }
    
    func strip04Prefix() -> String {
        if self.hasPrefix("04") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }
    
}
