// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "TorusUtils",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "TorusUtils",
            targets: ["TorusUtils"])
    ],
    dependencies: [
        .package(name: "curvelib.swift", url: "https://github.com/tkey/curvelib.swift", from: "0.1.2"),
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift", from: "5.1.0"),
        .package(name:"CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift",from: "1.5.1"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit", from: "4.0.0"),
        .package(
            name:"AnyCodable",
            url: "https://github.com/Flight-School/AnyCodable",
            from: "0.6.0"
        ),
    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: ["FetchNodeDetails", "CryptoSwift", "AnyCodable", .product(name: "curveSecp256k1", package: "curvelib.swift")]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", .product(name: "JWTKit", package: "jwt-kit")]
        )
    ],
    swiftLanguageVersions: [.v5]
)

