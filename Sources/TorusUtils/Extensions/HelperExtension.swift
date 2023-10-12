import Foundation
import BigInt

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}

extension BigUInt {
    init?(hex: String) {
        guard let result = BigUInt(hex, radix: 16) else{
            return nil
        }
        self = result
    }
}
