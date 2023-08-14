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
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift.git",from: "4.0.1"),
        .package(name:"CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git",from: "1.7.2"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit.git", from: "4.13.0")
    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: ["FetchNodeDetails", "CryptoSwift"]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", "CryptoSwift", .product(name: "JWTKit", package: "jwt-kit"), "FetchNodeDetails"]
        )
    ],                                                                                                                         swiftLanguageVersions: [.v5]

)
