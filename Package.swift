// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "TorusUtils",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TorusUtils",
            targets: ["TorusUtils"])
    ],
    dependencies: [
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift.git",from: "4.0.0"),
        .package(name:"CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git",from: "1.5.1"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(name:"CryptorECC", url: "https://github.com/Kitura/BlueECC.git", from: "1.2.4"),

    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: ["FetchNodeDetails", "CryptoSwift", "CryptorECC"]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", "CryptoSwift", .product(name: "JWTKit", package: "jwt-kit"), "FetchNodeDetails"]
        )
    ],
    swiftLanguageVersions: [.v5]
)

