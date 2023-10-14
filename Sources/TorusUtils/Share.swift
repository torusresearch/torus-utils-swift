import BigInt
import Foundation

public class Share: Codable {
    var share: BigInt
    var shareIndex: BigInt

    public init(shareIndex: String, share: String) {
        self.share = BigInt(share, radix: 16)!
        self.shareIndex = BigInt(shareIndex, radix: 16)!
    }

    public init(shareIndex: BigInt, share: BigInt) {
        self.share = share
        self.shareIndex = shareIndex
    }
}
