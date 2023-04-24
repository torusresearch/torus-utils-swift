//
//  File.swift
//
//
//  Created by Dhruv Jaiswal on 23/11/22.
//

import Foundation
extension String {

    func padLeft(padChar: Character, count: Int) -> String {
        let str = self
        if str.count >= count {
            return str
        }
        var resultStr = ""
        while str.count < count - str.count {
            resultStr.append(padChar)
        }
        resultStr.append(str)
        return resultStr
    }

    mutating func stripPaddingLeft(padChar: Character) {
        while self.count > 1 && self.first == padChar {
            self.removeFirst()
        }
    }

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(utf8).base64EncodedString()
    }

    func strip04Prefix() -> String {
        if hasPrefix("04") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func strip0xPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func addLeading0sForLength64() -> String {
        if count < 64 {
            let toAdd = String(repeating: "0", count: 64 - count)
            return toAdd + self
        } else {
            return self
        }
        // String(format: "%064d", self)
    }
}

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        return (0 ..< count / 2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            return UInt8(self[startIndex ... endIndex], radix: 16)
        }
    }
}
