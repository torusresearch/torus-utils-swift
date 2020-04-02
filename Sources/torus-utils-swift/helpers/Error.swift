//
//  File.swift
//  
//
//  Created by Shubham on 2/4/20.
//

import Foundation

public enum TorusError: Error{
    case apiRequestFailed
    case errInResponse(Any)
}

extension TorusError: CustomDebugStringConvertible{
    public var debugDescription: String{
        switch self {
        case .apiRequestFailed:
            return "API request failed or No response from the node"
        case .errInResponse(let str):
            return "API resopnse error \(str)"
    }
}
