import Foundation
import BigInt

func generatePrivateExcludingIndexes(shareIndexes: [BigInt]) -> BigInt {
    let key = BigInt(SECP256K1.generatePrivateKey()!)
    if shareIndexes.contains(where: { $0 == key }) {
        return generatePrivateExcludingIndexes(shareIndexes: shareIndexes)
    }
    return key
}

func generateEmptyBNArray(length: Int) -> [BigInt] {
    return Array(repeating: BigInt(0), count: length)
}

func denominator(i: Int, innerPoints: [Point]) -> BigInt {
    var result = BigInt(1)
    let xi = innerPoints[i].x
    for j in (0..<innerPoints.count).reversed() {
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
    for k in 0..<innerPoints.count {
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
    for i in 0..<sortedPoints.count {
        let coefficients = interpolationPoly(i: i, innerPoints: sortedPoints)
        for k in 0..<sortedPoints.count {
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

func generateRandomPolynomial(degree: Int, secret: BigInt? = nil, deterministicShares: [Share]? = nil) throws -> Polynomial {
    var actualS = secret
    if secret == nil {
        actualS = generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
    }
    
    if deterministicShares == nil {
        var poly = [actualS!]
        for _ in 0..<degree {
            let share = generatePrivateExcludingIndexes(shareIndexes: poly)
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
        points[share.shareIndex.description.padding(toLength: 64, withPad: "0", startingAt: 0)] = Point(x: .bn(share.shareIndex), y: .bn(share.share))
    }
    
    let remainingDegree = degree - deterministicShares.count
    for _ in 0..<remainingDegree {
        var shareIndex = generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
        while points[shareIndex.description.padding(toLength: 64, withPad: "0", startingAt: 0)] != nil {
            shareIndex = generatePrivateExcludingIndexes(shareIndexes: [BigInt(0)])
        }
        points[String(shareIndex, radix: 16).leftPadding(toLength: 64, withPad: "0")] = Point(x: shareIndex, y: BigInt(SECP256K1.generatePrivateKey()!))
    }
    
    points["0"] = Point(x: BigInt(0), y: actualS!)
    return lagrangeInterpolatePolynomial(points: Array(points.values))
}


