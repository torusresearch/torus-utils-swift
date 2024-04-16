import Foundation

extension String {
    func hasHexPrefix() -> Bool {
        return hasPrefix("0x")
    }

    func addHexPrefix() -> String {
        if !hasPrefix("0x") {
            return "0x" + self
        }
        return self
    }

    func stripHexPrefix() -> String {
        if hasPrefix("0x") {
            let indexStart = index(startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func has04Prefix() -> Bool {
        return hasPrefix("04")
    }

    func add04Prefix() -> String {
        if !hasPrefix("04") {
            return "04" + self
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

    func addLeading0sForLength64() -> String {
        if count < 64 {
            let toAdd = String(repeating: "0", count: 64 - count)
            return toAdd + self
        } else {
            return self
        }
    }

    func customBytes() -> Array<UInt8> {
        data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }

    func toChecksumAddress() -> String {
        let lowerCaseAddress = stripHexPrefix().lowercased()
        let arr = Array(lowerCaseAddress)
        let hash = keccak256Data(lowerCaseAddress.data(using: .utf8) ?? Data() ).toHexString()
        
        //Array(lowerCaseAddress.sha3(.keccak256))
        var result = String()
        for i in 0 ... lowerCaseAddress.count - 1 {
            let iIndex = hash.index(hash.startIndex, offsetBy: i)
            if let val = hash[iIndex].hexDigitValue , val >= 8 {
                result.append(arr[i].uppercased())
            } else {
                result.append(arr[i])
            }
        }
        return result.addHexPrefix()
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
