import Foundation
import BigInt

struct ImportedShare {
    let pubKeyX: String
    let pubKeyY: String
    let encryptedShare: String
    let encryptedShareMetadata: EciesHex
    let nodeIndex: BigUInt
    let keyType: String
    let nonceData: String
    let nonceSignature: String

}
