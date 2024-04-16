// swift-tools-version:5.7
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
        .package(url: "https://github.com/tkey/curvelib.swift", branch: "feat/cocoapod"),
        .package(name:"FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift", branch: "feat/commonSources"),
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
            dependencies: ["AnyCodable", "FetchNodeDetails",
                .product(name: "curveSecp256k1", package: "curvelib.swift"),
                .product(name: "encryption_aes_cbc_sha512", package: "curvelib.swift"),
                .product(name: "curvelibSha3", package: "curvelib.swift")
            ]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", .product(name: "JWTKit", package: "jwt-kit")]
        )
    ]
)

