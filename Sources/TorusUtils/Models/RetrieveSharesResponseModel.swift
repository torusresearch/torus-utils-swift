import Foundation

public struct RetrieveSharesResponseModel {
    public let publicAddress: String
    public let privateKey: String

    public init(publicKey: String, privateKey: String) {
        publicAddress = publicKey
        self.privateKey = privateKey
    }
}

// legacy
public struct RetrieveDecryptAndReconstuctResponseModel {
    public let iv: String
    public let ephemPublicKey: String
    public let share: String
    public let pubKeyX: String
    public let pubKeyY: String
    public let mac: String

    public init(iv: String, ephemPublicKey: String, share: String, pubKeyX: String, pubKeyY: String, mac: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.share = share
        self.pubKeyX = pubKeyX
        self.pubKeyY = pubKeyY
        self.mac = mac
    }
}
