import BigInt
import Foundation

class Share {
    var share: BigInt
    var shareIndex: BigInt
    
    init(shareIndex: BigInt, share: BigInt) {
        self.share = share
        self.shareIndex = shareIndex
    }
    
    static func fromJSON(value: StringifiedType) -> Share? {
        guard let shareIndex = value["shareIndex"] as? BigInt,
              let share = value["share"] as? BigInt else {
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
