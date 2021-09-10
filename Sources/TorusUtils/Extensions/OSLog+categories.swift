//
//  File.swift
//  
//
//  Created by Shubham on 7/9/21.
//

import Foundation
import os

let subsystem = Bundle.main.bundleIdentifier ?? "com.torus.utils"

public struct Log{
    static let network = OSLog(subsystem: subsystem, category: "network")
    static let parsing = OSLog(subsystem: subsystem, category: "parsing")
    static let core = OSLog(subsystem: subsystem, category: "core")
//    static let shareRequest = OSLog(subsystem: subsystem, category: "shareRequest")
//    static let lagrangeInterpolation = OSLog(subsystem: subsystem, category: "lagrangeInterpolation")
}
