import Foundation
import BigInt

struct ImportedShare {
    let pubKeyX: String
    let pubKeyY: String
    let encryptedShare: String
    let encryptedShareMetadata: EciesHex
    let nodeIndex: Int
    let keyType: String
    let nonceData: String
    let nonceSignature: String

}
