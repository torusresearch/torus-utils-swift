import Foundation
import BigInt

func keccak256Data(_ data: Data) -> Data {
    return data.sha3(.keccak256)
}

func keccak256Hex(_ data: Data) -> String {
    let hash = keccak256Data(data)
    return "0x" + hash.map { String(format: "%02x", $0) }.joined()
}

func stripHexPrefix(_ str: String) -> String {
    return str.hasPrefix("0x") ? String(str.dropFirst(2)) : str
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) throws -> String {
    let publicKeyHex = publicKeyX.addLeading0sForLength64()  + publicKeyY.addLeading0sForLength64()
    guard let publicKeyData = Data(hexString: publicKeyHex)
    else {
        throw TorusUtilError.runtime("Invalid public key when deriving etherium address")
    }
    let ethAddrData = publicKeyData.sha3(.keccak256).suffix(20)
    let ethAddrlower = "0x" + ethAddrData.toHexString()
    return ethAddrlower.toChecksumAddress()
}

func getPostboxKeyFrom1OutOf1(privKey: String, nonce: String) -> String {
    guard let privKeyBigInt = BigInt(privKey, radix: 16),
          let nonceBigInt = BigInt(nonce, radix: 16),
          let modulus = BigInt(CURVE_N, radix: 16) else {
        return ""
    }
    
    let result = (privKeyBigInt - nonceBigInt).modulus(modulus)
    return result.serialize().toHexString()
}

func normalizeKeysResult(keyArr: [VerifierLookupResponse.Key]) -> VerifierLookupResponse {
    var finalResult: VerifierLookupResponse = VerifierLookupResponse(keys: [], is_new_key: false, node_index: "0")
    
    if (!keyArr.isEmpty) {
        finalResult.keys = keyArr.map { key in
            return VerifierLookupResponse.Key(pub_key_X: key.pub_key_X, pub_key_Y: key.pub_key_Y, address: key.address)
        }
    }
    return finalResult
}

func kCombinations(s: Any, k: Int) -> [[Int]] {
    var set: [Int]
    if let number = s as? Int {
        set = Array(0..<number)
    } else if let numbers = s as? [Int] {
        set = numbers
    } else {
        return []
    }
    
    if k > set.count || k <= 0 {
        return []
    }
    
    if k == set.count {
        return [set]
    }
    
    if k == 1 {
        return set.map { [$0] }
    }
    
    var combs: [[Int]] = []
    var tailCombs: [[Int]] = []
    
    for i in 0...set.count - k {
        tailCombs = kCombinations(s: Array(set[(i + 1)...]), k: k - 1)
        for j in 0..<tailCombs.count {
            combs.append([set[i]] + tailCombs[j])
        }
    }
    
    return combs
}

func thresholdSame<T: Equatable>(arr: [T], t: Int) -> T? {
    var hashMap: [String: Int] = [:]
    for element in arr {
        let str = "\(element)"
        hashMap[str] = (hashMap[str] ?? 0) + 1
        if hashMap[str] == t {
            return element
        }
    }
    return nil
}

func encParamsBufToHex(encParams: Ecies) -> EciesHex {
    let ivString = encParams.iv
    let ephemPublicKeyString = encParams.ephemPublicKey
    let ciphertextString = encParams.ciphertext
    let macString = encParams.mac
    
    return EciesHex(iv: ivString,
                    ephemPublicKey: ephemPublicKeyString,
                    ciphertext: ciphertextString,
                    mac: macString,
                    mode: "AES256")
}


func encParamsHexToBuf(eciesData: EciesHexOmitCiphertext) -> EciesOmitCiphertext {
    return EciesOmitCiphertext(iv: eciesData.iv,
                               ephemPublicKey: eciesData.ephemPublicKey,
                               mac: eciesData.mac)
}



extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}


func array32toTuple(_ arr: [UInt8]) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
    return (arr[0] as UInt8, arr[1] as UInt8, arr[2] as UInt8, arr[3] as UInt8, arr[4] as UInt8, arr[5] as UInt8, arr[6] as UInt8, arr[7] as UInt8, arr[8] as UInt8, arr[9] as UInt8, arr[10] as UInt8, arr[11] as UInt8, arr[12] as UInt8, arr[13] as UInt8, arr[14] as UInt8, arr[15] as UInt8, arr[16] as UInt8, arr[17] as UInt8, arr[18] as UInt8, arr[19] as UInt8, arr[20] as UInt8, arr[21] as UInt8, arr[22] as UInt8, arr[23] as UInt8, arr[24] as UInt8, arr[25] as UInt8, arr[26] as UInt8, arr[27] as UInt8, arr[28] as UInt8, arr[29] as UInt8, arr[30] as UInt8, arr[31] as UInt8, arr[32] as UInt8, arr[33] as UInt8, arr[34] as UInt8, arr[35] as UInt8, arr[36] as UInt8, arr[37] as UInt8, arr[38] as UInt8, arr[39] as UInt8, arr[40] as UInt8, arr[41] as UInt8, arr[42] as UInt8, arr[43] as UInt8, arr[44] as UInt8, arr[45] as UInt8, arr[46] as UInt8, arr[47] as UInt8, arr[48] as UInt8, arr[49] as UInt8, arr[50] as UInt8, arr[51] as UInt8, arr[52] as UInt8, arr[53] as UInt8, arr[54] as UInt8, arr[55] as UInt8, arr[56] as UInt8, arr[57] as UInt8, arr[58] as UInt8, arr[59] as UInt8, arr[60] as UInt8, arr[61] as UInt8, arr[62] as UInt8, arr[63] as UInt8)
}
