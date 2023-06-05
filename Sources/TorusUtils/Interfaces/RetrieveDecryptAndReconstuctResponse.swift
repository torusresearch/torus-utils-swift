import Foundation

public struct RetrieveDecryptAndReconstuctResponse {
    public let iv: String
    public let ephemPublicKey: String
    public let share: String
    public let pubKeyX: String
    public let pubKeyY: String

    public init(iv: String, ephemPublicKey: String, share: String, pubKeyX: String, pubKeyY: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.share = share
        self.pubKeyX = pubKeyX
        self.pubKeyY = pubKeyY
    }
}
