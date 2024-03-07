// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAlamofireExtension",
    platforms: [.iOS("15.0"), .macOS("12")],
    products: [
        .library(
            name: "SwiftAlamofireExtension",
            targets: ["SwiftAlamofireExtension"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/hcmc-studio/swift-concurrency-extension",
            branch: "0.0.71"
        ),
        .package(
            url: "https://github.com/hcmc-studio/swift-protocol-extension.git",
            branch: "0.0.71"
        ),
        .package(
            url: "https://github.com/hcmc-studio/swift-type-extension",
            branch: "0.0.71"
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire",
            .upToNextMajor(from: "5.8.0")
        ),
        .package(
            url: "https://github.com/apple/swift-algorithms.git",
            .upToNextMajor(from: "1.1.0")
        ),
    ],
    targets: [
        .target(
            name: "SwiftAlamofireExtension",
            dependencies: [
                .product(name: "SwiftConcurrencyExtension", package: "swift-concurrency-extension"),
                .product(name: "SwiftProtocolExtension", package: "swift-protocol-extension"),
                .product(name: "SwiftTypeExtension", package: "swift-type-extension"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                "Alamofire",
            ]
        ),
        .testTarget(
            name: "SwiftAlamofireExtensionTests",
            dependencies: ["SwiftAlamofireExtension"]
        ),
    ]
)
