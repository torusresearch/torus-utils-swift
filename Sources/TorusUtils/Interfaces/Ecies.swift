import Foundation

protocol EciesProtocol {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}

struct EciesHex: EciesProtocol {
    var iv: Data
    var ephemPublicKey: Data
    var ciphertext: Data
    var mac: Data
    var mode: String?
}

struct Ecies: EciesProtocol {
    var iv: Data
    var ephemPublicKey: Data
    var ciphertext: Data
    var mac: Data

    init(iv: Data, ephemPublicKey: Data, ciphertext: Data, mac: Data) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
    }
}
