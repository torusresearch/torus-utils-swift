import Foundation
import SwiftKeccak

func stripHexPrefix(_ str: String) -> String {
    return str.hasPrefix("0x") ? String(str.dropFirst(2)) : str
}

func generateAddressFromPrivKey(domain dom, privateKey: privateKey) -> String {
    let pubKey = ECPublicKey(privateKey: privKey)
    print(pubKey, "public key")
    return publicKeyToAddress(pubKey)
}

func generateAddressFromPubKey(domain dom, w: pt) -> String {
    let pubKey = try ECPublicKey(domain: dom, w: pt)
    print(pubKey, "public key")
    return publicKeyToAddress(pubKey)
}

func getPostboxKeyFrom1OutOf1(domain dom, privKey: String, nonce: String) -> String {
    let privKeyBN = BigInt(privKey, base: 16)
    let nonceBN = BigInt(nonce, base: 16)
    return (privKeyBN.magnitude.subtracting(nonceBN) % getOrderOfCurve()).toHexString();
}
