import Foundation
import BigInt

func convertMetadataToNonce(params: [String: Any]?) -> BigUInt {
    guard let params = params, let message = params["message"] as? String else {
        return BigUInt(0)
    }
    return BigUInt(message, radix: 16) ?? BigUInt(0)
}
