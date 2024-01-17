import BigInt
import Foundation
#if canImport(curvelib_swift)
    import curvelib_swift
#endif

func modInverse(_ a: BigInt, _ m: BigInt) -> BigInt? {
    var (t, newT) = (BigInt(0), BigInt(1))
    var (r, newR) = (m, a)

    while newR != 0 {
        let quotient = r / newR
        (t, newT) = (newT, t - quotient * newT)
        (r, newR) = (newR, r - quotient * newR)
    }

    if r > 1 {
        return nil // Modular inverse does not exist
    }
    if t < 0 {
        t += m
    }

    return t
}

func generatePrivateExcludingIndexes(shareIndexes: [BigInt]) throws -> BigInt {
    let key = BigInt(Data(hex: try SecretKey().serialize().addLeading0sForLength64()))
    if shareIndexes.contains(where: { $0 == key }) {
        return try generatePrivateExcludingIndexes(shareIndexes: shareIndexes)
    }
    return key
}

func generateEmptyBNArray(length: Int) -> [BigInt] {
    return Array(repeating: BigInt(0), count: length)
}

func denominator(i: Int, innerPoints: [Point]) -> BigInt {
    var result = BigInt(1)
    let xi = innerPoints[i].x
    for j in (0 ..< innerPoints.count).reversed() {
        if i != j {
            var tmp = xi
            tmp = tmp - innerPoints[j].x
            tmp %= getOrderOfCurve()
            result = result * tmp
            result %= getOrderOfCurve()
        }
    }
    return result
}

func interpolationPoly(i: Int, innerPoints: [Point]) -> [BigInt] {
    var coefficients = generateEmptyBNArray(length: innerPoints.count)
    let d = denominator(i: i, innerPoints: innerPoints)
    if d == BigInt(0) {
        fatalError("Denominator for interpolationPoly is 0")
    }
    coefficients[0] = d.inverse(getOrderOfCurve())!
    for k in 0 ..< innerPoints.count {
        var newCoefficients = generateEmptyBNArray(length: innerPoints.count)
        if k != i {
            var j: Int
            if k < i {
                j = k + 1
            } else {
                j = k
            }
            j -= 1
            while j >= 0 {
                newCoefficients[j + 1] = newCoefficients[j + 1] + coefficients[j] % getOrderOfCurve()
                var tmp = BigInt(innerPoints[k].x)
                tmp = tmp * coefficients[j] % getOrderOfCurve()
                newCoefficients[j] = newCoefficients[j] - tmp % getOrderOfCurve()
                j -= 1
            }
            coefficients = newCoefficients
        }
    }
    return coefficients
}

func pointSort(innerPoints: [Point]) -> [Point] {
    var pointArrClone = innerPoints
    pointArrClone.sort { $0.x < $1.x }
    return pointArrClone
}

func lagrange(unsortedPoints: [Point]) -> Polynomial {
    let sortedPoints = pointSort(innerPoints: unsortedPoints)
    var polynomial = generateEmptyBNArray(length: sortedPoints.count)
    for i in 0 ..< sortedPoints.count {
        let coefficients = interpolationPoly(i: i, innerPoints: sortedPoints)
        for k in 0 ..< sortedPoints.count {
            var tmp = BigInt(sortedPoints[i].y)
            tmp = tmp * coefficients[k] % getOrderOfCurve()
            polynomial[k] = (polynomial[k] + tmp) % getOrderOfCurve()
        }
    }
    return Polynomial(polynomial: polynomial)
}

func lagrangeInterpolatePolynomial(points: [Point]) -> Polynomial {
    return lagrange(unsortedPoints: points)
}

func lagrangeInterpolationWithNodeIndex(shares: [BigInt], nodeIndex: [BigInt]) -> BigInt {
    let modulus = BigInt(CURVE_N, radix: 16)!

    if shares.count != nodeIndex.count {
        fatalError("shares not equal to nodeIndex length in lagrangeInterpolation")
    }

    var secret = BigInt(0)
    for i in 0 ..< shares.count {
        var upper = BigInt(1)
        var lower = BigInt(1)
        for j in 0 ..< shares.count {
            if i != j {
                upper *= -nodeIndex[j]
                upper %= modulus
                var temp = nodeIndex[i] - nodeIndex[j]
                temp %= modulus
                lower *= temp
                lower %= modulus
            }
        }
        var delta = upper * modInverse(lower, modulus)!
        delta %= modulus
        delta = delta * shares[i]
        delta %= modulus
        secret += delta
    }

    return secret % modulus
}

func generateRandomPolynomial(degree: Int, secret: BigInt? = nil, deterministicShares: [Share]? = nil) throws -> Polynomial {
    var actualS = secret
    if secret == nil {
        actualS = try generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
    }

    if deterministicShares == nil {
        var poly = [actualS!]
        for _ in 0 ..< degree {
            let share = try generatePrivateExcludingIndexes(shareIndexes: poly)
            poly.append(share)
        }

        return Polynomial(polynomial: poly)
    }

    guard let deterministicShares = deterministicShares else {
        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Deterministic shares in generateRandomPolynomial should be an array"])
    }

    if deterministicShares.count > degree {
        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Deterministic shares in generateRandomPolynomial should be less or equal than degree to ensure an element of randomness"])
    }

    var points = [String: Point]()
    for share in deterministicShares {
        points[String(share.shareIndex, radix: 16).addLeading0sForLength64()] =
            Point(x: share.shareIndex, y: share.share)
    }

    let remainingDegree = degree - deterministicShares.count
    for _ in 0 ..< remainingDegree {
        var shareIndex = try generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
        while points[shareIndex.description.padding(toLength: 64, withPad: "0", startingAt: 0)] != nil {
            shareIndex = try generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
        }
        points[String(shareIndex, radix: 16).addLeading0sForLength64()] = Point(x: shareIndex, y: BigInt(Data(hex:try SecretKey().serialize().addLeading0sForLength64())))
    }

    points["0"] = Point(x: BigInt(0), y: actualS!)
    return lagrangeInterpolatePolynomial(points: Array(points.values))
}
