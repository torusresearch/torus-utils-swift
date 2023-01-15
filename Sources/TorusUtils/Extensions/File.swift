//
//  File.swift
//  
//
//  Created by Dhruv Jaiswal on 15/01/23.
//

import Foundation
import Combine
import OSLog


extension TorusUtils{

    func keyLookup(endpoints: [String], verifier: String, verifierId: String) async throws -> [String:String]{
        let encoder = JSONEncoder()
        
        let jsonRPCRequest = JSONRPCrequest(
            method: "VerifierLookupRequest",
            params: ["verifier": verifier, "verifier_id": verifierId])
        guard let rpcdata = try? encoder.encode(jsonRPCRequest)
        else {
            throw TorusUtilError.encodingFailed("\(jsonRPCRequest)")
        }
        var allowHostRequest = try! makeUrlRequest(url: allowHost)
        allowHostRequest.httpMethod = "GET"
        allowHostRequest.addValue("torus-default", forHTTPHeaderField: "x-api-key")
        allowHostRequest.addValue(verifier, forHTTPHeaderField: "Origin")
        do {
            _ = try await urlSession.data(for: allowHostRequest)
        } catch {
            os_log("KeyLookup: signer allow: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
            throw error
        }
        
        // Create Array of URLRequest Promises
        
        var lookupCount = 0
        var resultArray = [[String: String]?].init(repeating: nil, count: endpoints.count)
        // var promisesArray: [(data: Data, response: URLResponse)] = []
        var requestArray = [URLRequest]()
        for (_,el) in endpoints.enumerated() {
            do {
                var rq = try makeUrlRequest(url: el)
                rq.httpBody = rpcdata
                requestArray.append(rq)
            } catch {
                throw error
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var taskArr = [AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>]()
            for i in 1..<requestArray.count{
                let task = self.urlSession.dataTaskPublisher(for: requestArray[i])
                    .eraseToAnyPublisher()
                    taskArr.append(task)
                
            }
            let combinedTasks = Publishers.MergeMany(taskArr)
            
            combinedTasks.sink { val in
                switch val{
                case .finished:
                    print("Done")
                case .failure(let error):
                    let tmpError = error as NSError
                    let userInfo = tmpError.userInfo as [String: Any]
                    if tmpError.code == -1003 {
                        // In case node is offline
                        os_log("keyLookup: DNS lookup failed, node %@ is probably offline.", log: getTorusLogger(log: TorusUtilsLogger.network, type: .error), type: .error, userInfo["NSErrorFailingURLKey"].debugDescription)

                        // reject if threshold nodes unavailable
                        lookupCount += 1
                        if lookupCount > Int(endpoints.count / 2) {
                            continuation.resume(throwing: TorusUtilError.nodesUnavailable)
                        }
                    } else {
                        // throw TorusUtilError.nodesUnavailable
                        os_log("keyLookup: err: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .error), type: .error, error.localizedDescription)
                    }
                }
            } receiveValue: { val in
                lookupCount += 1
                let data = val.data
                print(try! JSONSerialization.jsonObject(with: data) )
                do{
                    let decoded = try JSONDecoder().decode(JSONRPCresponse.self, from: data) // User decoder to covert to struct
                    os_log("keyLookup: API response: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, "\(decoded)")
                    
                    let result = decoded.result
                    let error = decoded.error
                    if let _ = error {
                        resultArray.append(["err": decoded.error?.data ?? "nil"])
                    } else {
                        guard
                            let decodedResult = result as? [String: [[String: String]]],
                            let k = decodedResult["keys"]
                        else {
                            return continuation.resume(throwing: TorusUtilError.decodingFailed("keys not found in \(result ?? "")"))
                        }
                        let keys = k[0] as [String: String]
                        resultArray.append(keys)
                    }
                    
                    let lookupShares = resultArray.filter { $0 != nil } // Nonnil elements
                    let keyResult = self.thresholdSame(arr: lookupShares, threshold: Int(endpoints.count / 2) + 1) // Check if threshold is satisfied
                    
                    if keyResult != nil {
                        os_log("keyLookup: fulfill: %@", log: getTorusLogger(log: TorusUtilsLogger.core, type: .debug), type: .debug, keyResult!.debugDescription)
                        print(keyResult!!)
                        self.subscription = []
                        continuation.resume(returning: keyResult!!)
                    }
                }
                catch{
                    continuation.resume(throwing: TorusUtilError.decodingFailed())
                }
            }
            .store(in: &subscription)
        }
    }
}
