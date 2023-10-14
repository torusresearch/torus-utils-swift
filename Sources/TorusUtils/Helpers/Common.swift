import BigInt
import Foundation

func keccak256Data(_ data: Data) -> Data {
    return data.sha3(.keccak256)
}

func generateAddressFromPubKey(publicKeyX: String, publicKeyY: String) -> String {
    let publicKeyHex = publicKeyX.addLeading0sForLength64() + publicKeyY.addLeading0sForLength64()
    let publicKeyData = Data(hex: publicKeyHex)
    let ethAddrData = publicKeyData.sha3(.keccak256).suffix(20)
    let ethAddrlower = "0x" + ethAddrData.toHexString()
    return ethAddrlower.toChecksumAddress()
}

func kCombinations(s: Any, k: Int) -> [[Int]] {
    var set: [Int]
    if let number = s as? Int {
        set = Array(0 ..< number)
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

    for i in 0 ... set.count - k {
        tailCombs = kCombinations(s: Array(set[(i + 1)...]), k: k - 1)
        for j in 0 ..< tailCombs.count {
            combs.append([set[i]] + tailCombs[j])
        }
    }

    return combs
}
