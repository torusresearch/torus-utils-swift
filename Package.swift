// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "torus-utils-swift",
    products: [
        .library(
            name: "torus-utils-swift",
            targets: ["torus-utils-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rathishubham7/web3swift", from:"2.2.2"),
        .package(url: "https://github.com/torusresearch/fetch-node-details-swift", from:"0.0.4"),
        .package(url: "https://github.com/PromiseKit/Foundation.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "torus-utils-swift",
            dependencies: ["fetch-node-details", "web3swift", "PMKFoundation"]),
        .testTarget(
            name: "torus-utils-swiftTests",
            dependencies: ["torus-utils-swift"]),
    ]
)
