//  web3swift
//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation

extension String {
    var fullRange: Range<Index> {
        return startIndex ..< endIndex
    }

    var fullNSRange: NSRange {
        return NSRange(fullRange, in: self)
    }

    func index(of char: Character) -> Index? {
        guard let range = range(of: String(char)) else {
            return nil
        }
        return range.lowerBound
    }

    func split(intoChunksOf chunkSize: Int) -> [String] {
        var output = [String]()
        let splittedString = map { $0 }
            .split(intoChunksOf: chunkSize)
        splittedString.forEach {
            output.append($0.map { String($0) }.joined(separator: ""))
        }
        return output
    }

    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ... end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }

    subscript(bounds: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = endIndex
        return String(self[start ..< end])
    }

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }

    func interpretAsBinaryData() -> Data? {
        let padded = padding(toLength: ((count + 7) / 8) * 8, withPad: "0", startingAt: 0)
        let byteArray = padded.split(intoChunksOf: 8).map { UInt8(strtoul($0, nil, 2)) }
        return Data(byteArray)
    }

    func hasHexPrefix() -> Bool {
        return hasPrefix("0x")
    }

    func stripHexPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func addHexPrefix() -> String {
        if !hasPrefix("0x") {
            return "0x" + self
        }
        return self
    }

    func stripLeadingZeroes() -> String? {
        let hex = addHexPrefix()
        guard let matcher = try? NSRegularExpression(pattern: "^(?<prefix>0x)0*(?<end>[0-9a-fA-F]*)$", options: NSRegularExpression.Options.dotMatchesLineSeparators) else { return nil }
        let match = matcher.captureGroups(string: hex, options: NSRegularExpression.MatchingOptions.anchored)
        guard let prefix = match["prefix"] else { return nil }
        guard let end = match["end"] else { return nil }
        if end != "" {
            return prefix + end
        }
        return "0x0"
    }

    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
        return results.map { result in
            (0 ..< result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }

    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
        else { return nil }
        return from ..< to
    }

    var asciiValue: Int {
        let s = unicodeScalars
        return Int(s[s.startIndex].value)
    }
}

extension Character {
    var asciiValue: Int {
        let s = String(self).unicodeScalars
        return Int(s[s.startIndex].value)
    }
}

extension String {
    func toChecksumAddress() -> String {
        let lowerCaseAddress = stripHexPrefix().lowercased()
        let arr = Array(lowerCaseAddress)
        let hash = Array(lowerCaseAddress.sha3(.keccak256))
        var result = "0x"
        for i in 0 ... lowerCaseAddress.count - 1 {
            if let val = Int(String(hash[i]), radix: 16), val >= 8 {
                result.append(arr[i].uppercased())
            } else {
                result.append(arr[i])
            }
        }
        return result
    }
}
