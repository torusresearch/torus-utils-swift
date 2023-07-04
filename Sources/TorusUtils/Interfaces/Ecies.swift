import Foundation

protocol EciesProtocol {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}

struct EciesHex {
    let iv: String
    let ephemPublicKey: String
    let ciphertext: String
    let mac: String
    let mode: String?
    
    init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String, mode: String?) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
        self.mode = mode
    }
    
    func omitCiphertext() -> EciesHexOmitCiphertext {
        return EciesHexOmitCiphertext(iv: self.iv, ephemPublicKey: self.ephemPublicKey, mac: self.mac, mode: self.mode)
    }
    
}

struct EciesHexOmitCiphertext {
    var iv: String
    var ephemPublicKey: String
    var mac: String
    var mode: String?
}

public struct Ecies: EciesProtocol {
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

struct EciesOmitCiphertext {
    var iv: Data
    var ephemPublicKey: Data
    var mac: Data
}
