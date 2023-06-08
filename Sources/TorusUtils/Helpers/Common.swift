import Foundation
import CryptoKit


func normalizeKeysResult(result: VerifierLookupResponse) -> VerifierLookupResponse {
    var finalResult: VerifierLookupResponse = VerifierLookupResponse(keys: [], is_new_key: false, node_index: 0)
    if let keys = result.keys, !keys.isEmpty {
        finalResult.keys = keys.map { key in
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
    return EciesHex(iv: encParams.iv,
                    ephemPublicKey: encParams.ephemPublicKey,
                    ciphertext: encParams.ciphertext,
                    mac: encParams.mac,
                    mode: "AES256")
}

func encParamsHexToBuf(eciesData: EciesHex) -> Ecies {
    return Ecies(iv: eciesData.iv,
                 ephemPublicKey: eciesData.ephemPublicKey,
                 ciphertext: eciesData.ciphertext,
                 mac: eciesData.mac)
}
