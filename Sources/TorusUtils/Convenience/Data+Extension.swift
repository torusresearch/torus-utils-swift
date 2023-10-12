import Foundation

public extension Data {
    init?(hexString: String) {
        let input = hexString.stripHexPrefix()
        let length = input.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = input.index(input.startIndex, offsetBy: i * 2)
            let k = input.index(j, offsetBy: 2)
            let bytes = input[j ..< k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }


    func addLeading0sForLength64() -> Data {
        Data(hex: toHexString().addLeading0sForLength64())
    }
}
