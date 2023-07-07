import Foundation

protocol EciesProtocol {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}


public struct ECIES : Codable {
    let iv: String
    let ephemPublicKey: String
    let ciphertext: String
    let mac: String
    let mode: String?
    
    init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String, mode: String?=nil) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
        self.mode = mode
    }
}

public struct EciesHex : Codable {
    let iv: String
    let ephemPublicKey: String
    let ciphertext: String?
    let mac: String
    let mode: String?
    
    init(iv: String, ephemPublicKey: String, ciphertext: String?, mac: String, mode: String?) {
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
    
    init(iv: String, ephemPublicKey: String, mac: String, mode: String? = nil) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.mac = mac
        self.mode = mode
    }
    
    init(from: ECIES) {
        self.iv = from.iv
        self.ephemPublicKey = from.ephemPublicKey
        self.mac = from.mac
        self.mode = from.mode
    }
}

public struct Ecies: Codable {
    var iv: String
    var ephemPublicKey: String
    var ciphertext: String
    var mac: String
    
    init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String) {
        self.iv = iv
        self.ephemPublicKey = ephemPublicKey
        self.ciphertext = ciphertext
        self.mac = mac
    }
}

struct EciesOmitCiphertext {
    var iv: String
    var ephemPublicKey: String
    var mac: String
}
