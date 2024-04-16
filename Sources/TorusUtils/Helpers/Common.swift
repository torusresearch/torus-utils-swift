import BigInt
import Foundation
//import CryptoSwift

import curveSecp256k1

func keccak256Data(_ data: Data) -> Data {
    let hash = try? keccak256(data: data)
    return hash ?? Data([])
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) -> String {
    let publicKeyHex = publicKeyX.addLeading0sForLength64() + publicKeyY.addLeading0sForLength64()
    let publicKeyData = Data(hex: publicKeyHex)
//    let ethAddrData = publicKeyData.sha3(.keccak256).suffix(20)
    let ethAddrData = try keccak256Data(publicKeyData).suffix(20)
    let ethAddrlower = ethAddrData.toHexString().addHexPrefix()
    return ethAddrlower.toChecksumAddress()
}
