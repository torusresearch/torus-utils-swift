//
//  File.swift
//  
//
//  Created by Dhruv Jaiswal on 17/11/22.
//

import Foundation
/*
Fix for the issue
 https://www.swiftbysundell.com/articles/making-async-system-apis-backward-compatible/
*/
@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse){
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
