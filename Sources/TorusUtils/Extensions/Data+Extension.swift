import Foundation

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }

    public func addLeading0sForLength64() -> Data {
        Data(hex: hexString.addLeading0sForLength64())
    }

    init(hex: String) {
        self.init(Array<UInt8>(hex: hex))
    }

    var bytes: Array<UInt8> {
        Array(self)
    }

    func toHexString() -> String {
        bytes.toHexString()
    }
}
