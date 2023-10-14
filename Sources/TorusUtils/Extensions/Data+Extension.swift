import Foundation

public extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }

    func addLeading0sForLength64() -> Data {
        Data(hex: hexString.addLeading0sForLength64())
    }
}
