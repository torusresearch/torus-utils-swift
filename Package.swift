// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TorusUtils",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "TorusUtils",
            targets: ["TorusUtils"]),
    ],
    dependencies: [
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift", from: "1.4.0"),
        .package(name:"PMKFoundation", url: "https://github.com/PromiseKit/Foundation.git", from: "3.4.0"),
        .package(name:"PromiseKit", url: "https://github.com/mxcl/PromiseKit.git", from: "6.0.0"),
        .package(name:"CryptorECC", url: "https://github.com/IBM-Swift/BlueECC.git", from: "1.2.4"),
        .package(name:"CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(name:"web3.swift", url: "https://github.com/argentlabs/web3.swift", from:"0.8.1"),
        .package(name:"secp256k1", url: "https://github.com/Boilertalk/secp256k1.swift", from: "0.1.0"),
        .package(name: "TweetNacl", url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: ["FetchNodeDetails", "CryptoSwift", "web3.swift", "CryptorECC", "secp256k1", "PMKFoundation", "PromiseKit", "TweetNacl"]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", .product(name: "JWTKit", package: "jwt-kit"), "FetchNodeDetails", "web3.swift", .product(name: "PromiseKit", package: "PromiseKit"), "PMKFoundation", "CryptorECC"]),
    ]
)
