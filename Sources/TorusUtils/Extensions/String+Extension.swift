import Foundation

extension String {
    func addHexPrefix() -> String {
        if hasPrefix("0x") {
            return self
        }
        return "0x" + self
    }
    
    func add04PrefixUnchecked() -> String {
        return "04" + self
    }

    func stripHexPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func strip04Prefix() -> String {
        if hasPrefix("04") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    public func addLeading0sForLength64() -> String {
        if count < 64 {
            let toAdd = String(repeating: "0", count: 64 - count)
            return toAdd + self
        } else {
            return self
        }
    }
    
    public func addLeading0sForLength128() -> String {
        if count < 128 {
            let toAdd = String(repeating: "0", count: 128 - count)
            return toAdd + self
        } else {
            return self
        }
    }

    public func hexEncodedToString() -> String {
        var finalString = ""
        var chars = Array(self)

        if (chars.count % 2) != 0 { // odd number of characters in hex, pad with single zero.
            chars.insert("0", at: 0)
        }
        
        for count in stride(from: 0, to: chars.count - 1, by: 2) {
            let firstDigit = Int("\(chars[count])", radix: 16) ?? 0
            let lastDigit = Int("\(chars[count + 1])", radix: 16) ?? 0
            let decimal = firstDigit * 16 + lastDigit
            let decimalString = String(format: "%c", decimal) as String
            if !(decimalString.isEmpty) { // lossy conversion
                finalString.append(Character(decimalString))
            }
        }
        return finalString
    }
}
