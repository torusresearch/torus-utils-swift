import BigInt
import Foundation

internal class Share: Codable {
    var share: BigInt
    var shareIndex: BigInt

    public init(shareIndex: String, share: String) throws {
        if let si = BigInt(shareIndex, radix: 16) {
            self.shareIndex = si
        } else {
            SentryUtils.captureException("\(TorusUtilError.invalidInput) for client id: \(TorusUtils.getClientId())")
            throw TorusUtilError.invalidInput
        }

        if let s = BigInt(share, radix: 16) {
            self.share = s
        } else {
            SentryUtils.captureException("\(TorusUtilError.invalidInput) for client id: \(TorusUtils.getClientId())")
            throw TorusUtilError.invalidInput
        }
    }

    public init(shareIndex: BigInt, share: BigInt) {
        self.share = share
        self.shareIndex = shareIndex
    }
}
