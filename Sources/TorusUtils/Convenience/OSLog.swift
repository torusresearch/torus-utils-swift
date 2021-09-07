//
//  File.swift
//  
//
//  Created by Shubham on 7/9/21.
//

import Foundation
import os

let subsystem = "com.torus.utils"

public struct Log{
    static let retrieveShares = OSLog(subsystem: subsystem, category: "retrieveShares")
    static let getPublicAddress = OSLog(subsystem: subsystem, category: "getPublicAddress")
    static let commitmentRequest = OSLog(subsystem: subsystem, category: "commitmentRequest")
    static let shareRequest = OSLog(subsystem: subsystem, category: "shareRequest")
    static let lagrangeInterpolation = OSLog(subsystem: subsystem, category: "lagrangeInterpolation")
}
