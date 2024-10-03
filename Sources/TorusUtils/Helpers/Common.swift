import BigInt
import FetchNodeDetails
import Foundation
#if canImport(curveSecp256k1)
    import curveSecp256k1
#endif

internal func normalizeKeysResult(result: VerifierLookupResponse) -> KeyLookupResult.KeyResult {
    var finalResult = KeyLookupResult.KeyResult(is_new_key: result.is_new_key)

    if !result.keys.isEmpty {
        let finalKey = result.keys[0]
        finalResult.keys = [
            VerifierLookupResponse.Key(
                pub_key_X: finalKey.pub_key_X,
                pub_key_Y: finalKey.pub_key_Y,
                address: finalKey.address
            ),
        ]
    }

    return finalResult
}

internal func kCombinations<T>(elements: ArraySlice<T>, k: Int) -> [[T]] {
    if k == 0 || k > elements.count {
        return []
    }

    if k == elements.count {
        return [Array(elements)]
    }

    if k == 1 {
        return elements.map { [$0] }
    }

    var combs: [[T]] = []
    var tailCombs: [[T]] = []

    for i in 0 ... (elements.count - k + 1) {
        tailCombs = kCombinations(elements: elements[(elements.startIndex + i + 1)...], k: k - 1)
        for item in tailCombs {
            var extended = [elements[elements.startIndex + i]]
            extended.append(contentsOf: item)
            combs.append(extended)
        }
    }

    return combs
}

internal func thresholdSame<T: Encodable>(arr: [T], threshold: Int) throws -> T? {
    var hashmap = [String: Int]()
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .sortedKeys
    for (_, value) in arr.enumerated() {
        guard let jsonString = String(data: try jsonEncoder.encode(value), encoding: .utf8) else { throw TorusUtilError.encodingFailed("thresholdSame")
        }
        if let _ = hashmap[jsonString] {
            hashmap[jsonString]! += 1
        } else {
            hashmap[jsonString] = 1
        }
        if hashmap[jsonString] == threshold {
            return value
        }
    }
    return nil
}

internal func calculateMedian(arr: [Int]) -> Int {
    let arrLen = arr.count

    if arrLen == 0 {
        return 0
    }

    var sortedArr = arr
    sortedArr = arr.sorted()

    if (arrLen % 2) != 0 {
        return sortedArr[Int(floor(Double(arrLen / 2 - 1)))]
    }

    let mid1 = sortedArr[Int(floor(Double(arrLen / 2 - 1)))]
    let mid2 = sortedArr[Int(floor(Double(arrLen / 2)))]

    return (mid1 + mid2) / 2
}

internal func getProxyCoordinatorEndpointIndex(endpoints: [String], verifier: String, verifierId: String) throws -> BigUInt {
    let verifierIdString = verifier + verifierId
    let hashedVerifierId = try KeyUtils.keccak256Data(verifierIdString)
    let proxyEndPointNum = BigInt(hashedVerifierId, radix: 16)!.modulus(BigInt(endpoints.count))
    return proxyEndPointNum.magnitude
}
