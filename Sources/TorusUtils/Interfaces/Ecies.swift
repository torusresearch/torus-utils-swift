import Foundation

struct EciesHex: Ecies {
    var iv: Data
    var ephemPublicKey: Data
    var ciphertext: Data
    var mac: Data
    var mode: String?
}

protocol Ecies {
    var iv: Data { get }
    var ephemPublicKey: Data { get }
    var ciphertext: Data { get }
    var mac: Data { get }
}


