import BigInt
import Foundation

func keccak256Data(_ data: Data) -> Data {
    return data.sha3(.keccak256)
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) -> String {
    let publicKeyHex = publicKeyX.addLeading0sForLength64() + publicKeyY.addLeading0sForLength64()
    let publicKeyData = Data(hex: publicKeyHex)
    let ethAddrData = publicKeyData.sha3(.keccak256).suffix(20)
    let ethAddrlower = ethAddrData.toHexString().addHexPrefix()
    return ethAddrlower.toChecksumAddress()
}
