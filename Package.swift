// swift-tools-version:5.2
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
        //        .package(url: "https://github.com/skywinder/web3swift", .branch("master")),
        .package(name:"BestLogger", url: "https://github.com/rathishubham7/swift-logger", from:"0.0.1"),
        //        .package(name:"FetchNodeDetails", path: "../fetch-node-details-swift"),
        .package(name:"PromiseKit", url: "https://github.com/mxcl/PromiseKit.git", from: "6.0.0"),
        .package(name:"PMKFoundation", url: "https://github.com/PromiseKit/Foundation.git", from: "3.0.0"),
        .package(name:"CryptorECC", url: "https://github.com/IBM-Swift/BlueECC.git", from: "1.2.4"),
        .package(name:"CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift", .branch("feat/argentweb3")),
        .package(name:"web3.swift", url: "https://github.com/argentlabs/web3.swift", from:"0.7.0"),
        .package(name:"secp256k1", url: "https://github.com/Boilertalk/secp256k1.swift", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: [.product(name: "FetchNodeDetails", package: "FetchNodeDetails"), "CryptoSwift", "web3.swift", "CryptorECC", "secp256k1", "PMKFoundation", "PromiseKit", "BestLogger"]),
        .testTarget(
            name: "torus-utils-swiftTests",
            dependencies: ["TorusUtils", .product(name: "JWTKit", package: "jwt-kit"), .product(name: "FetchNodeDetails", package: "FetchNodeDetails"), "web3.swift", .product(name: "PromiseKit", package: "PromiseKit"), "PMKFoundation", "CryptorECC", "BestLogger"]),
    ]
)
