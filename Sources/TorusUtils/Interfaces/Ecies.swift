import Foundation

protocol EciesProtocol {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}

struct EciesHex: EciesProtocol {
    private let ivString: String
    private let ephemPublicKeyString: String
    private let ciphertextString: String
    private let macString: String
    
    var iv: Data {
        return Data(hex: ivString)
    }
    
    var ephemPublicKey: Data {
        return Data(hex: ephemPublicKeyString)
    }
    
    var ciphertext: Data {
        return Data(hex: ciphertextString)
    }
    
    var mac: Data {
        return Data(hex: macString)
    }
    
    var mode: String?
    
    init(iv: String, ephemPublicKey: String, ciphertext: String, mac: String, mode: String?) {
        self.ivString = iv
        self.ephemPublicKeyString = ephemPublicKey
        self.ciphertextString = ciphertext
        self.macString = mac
        self.mode = mode
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
