import BigInt
import Foundation

class Share {
    var share: BigInt
    var shareIndex: BigInt
    
    init(shareIndex: BNString, share: BNString) {
        self.share = BigInt(share.toString()!, radix: 16)!
        self.shareIndex = BigInt(shareIndex.toString()!, radix: 16)!
    }
    
    static func fromJSON(value: StringifiedType) -> Share? {
        guard let shareIndex = value["shareIndex"] as? BNString,
              let share = value["share"] as? BNString else {
            return nil
        }
        
        return Share(shareIndex: shareIndex, share: share)
    }
    
    func toJSON() -> StringifiedType {
        return [
            "share": self.share.description,
            "shareIndex": self.shareIndex.description
        ]
    }
}
