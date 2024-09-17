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
        .package(url: "https://github.com/tkey/curvelib.swift", from: "1.0.1"),
        .package(url: "https://github.com/torusresearch/fetch-node-details-swift", from: "6.0.3"),
        // NB: jwt-kit may only be a dependency in tests or it will break cocoapod support
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.36.0"),
    ],
    targets: [
        .target(
            name: "TorusUtils",
            dependencies: [
                .product(name: "FetchNodeDetails", package: "fetch-node-details-swift"),
                .product(name: "curveSecp256k1", package: "curvelib.swift"),
                .product(name: "Sentry", package: "sentry-cocoa"),
            ]),
        .testTarget(
            name: "TorusUtilsTests",
            dependencies: ["TorusUtils", .product(name: "JWTKit", package: "jwt-kit")]
        )
    ]
)

