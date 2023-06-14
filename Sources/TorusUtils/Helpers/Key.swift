import Foundation
import CryptorECC

func stripHexPrefix(_ str: String) -> String {
    return str.hasPrefix("0x") ? String(str.dropFirst(2)) : str
}

func generateAddressFromPrivKey(privateKey: privateKey) -> String {
    let pubKey = try ECPublicKey(privateKey: privKey)
    print(pubKey, "public key")
    return publicKeyToAddress(pubKey)
}

func generateAddressFromPubKey(w: pt) -> String {
    let pubKey = try ECPublicKey(w: pt)
    print(pubKey, "public key")
    return publicKeyToAddress(pubKey)
}

func getPostboxKeyFrom1OutOf1(privKey: String, nonce: String) -> String {
    let privKeyBN = BigInt(privKey, base: 16)
    let nonceBN = BigInt(nonce, base: 16)
    return (privKeyBN.magnitude.subtracting(nonceBN) % getOrderOfCurve()).toHexString();
}
