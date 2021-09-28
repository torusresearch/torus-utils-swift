//
//  File.swift
//  
//
//  Created by Shubham on 7/9/21.
//

import Foundation
import os

let subsystem = Bundle.main.bundleIdentifier ?? "com.torus.utils"

public struct TorusUtilsLogger{
    static let inactiveLog = OSLog.disabled
    static let network = OSLog(subsystem: subsystem, category: "network")
    static let parsing = OSLog(subsystem: subsystem, category: "parsing")
    static let core = OSLog(subsystem: subsystem, category: "core")
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
func getTorusLogger(log: OSLog = .default, type: OSLogType = .default) -> OSLog {
    var logCheck: OSLog { utilsLogType.rawValue <= type.rawValue ? log : TorusUtilsLogger.inactiveLog}
    return logCheck
}

//@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
//func log(_ message: StaticString, dso: UnsafeRawPointer? = #dsohandle, log: OSLog = .default, type: OSLogType = .default, _ args: CVarArg...){
//    var logCheck: OSLog
//    if(utilsLogType.rawValue <= type.rawValue){
//        logCheck = log
//    }else{
//        logCheck = TorusUtilsLogger.inactiveLog
//    }
//    
//    // TODO: fix the variadic parameter limitation in swift
//    os_log(message, dso: dso, log: logCheck, type: type, args)
//}
