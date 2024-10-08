import Foundation

protocol EciesProtocol {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}

public struct ECIES: Codable {
    let iv: String
    let ephemPublicKey: String
    let ciphertext: String
    let mac: String
    let mode: String?

    public init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String, mode: String? = nil) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
        self.mode = mode
    }
}

public struct EciesHex: Codable {
    let iv: String
    let ephemPublicKey: String
    let ciphertext: String
    let mac: String
    let mode: String?

    public init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String, mode: String?) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
        self.mode = mode
    }

    public init(from: Ecies) {
        ciphertext = from.ciphertext
        iv = from.iv
        ephemPublicKey = from.ephemPublicKey
        mac = from.mac
        mode = "AES256"
    }

    public func omitCiphertext() -> EciesHexOmitCiphertext {
        return EciesHexOmitCiphertext(iv: iv, ephemPublicKey: ephemPublicKey, mac: mac, mode: mode)
    }
}

public struct EciesHexOmitCiphertext: Codable {
    var iv: String
    var ephemPublicKey: String
    var mac: String
    var mode: String?

    public init(iv: String, ephemPublicKey: String, mac: String, mode: String? = nil) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.mac = mac
        self.mode = mode
    }

    public init(from: ECIES) {
        iv = from.iv
        ephemPublicKey = from.ephemPublicKey
        mac = from.mac
        mode = from.mode
    }

    public init(from: Ecies) {
        iv = from.iv
        ephemPublicKey = from.ephemPublicKey
        mac = from.mac
        mode = "AES256"
    }
}

public struct Ecies: Codable {
    var iv: String
    var ephemPublicKey: String
    var ciphertext: String
    var mac: String

    public init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
    }
}

public struct EciesOmitCiphertext {
    var iv: String
    var ephemPublicKey: String
    var mac: String
}
