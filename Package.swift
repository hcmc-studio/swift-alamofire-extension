// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAlamofireExtension",
    platforms: [.iOS("13.0"), .macOS("10.15")],
    products: [
        .library(
            name: "SwiftAlamofireExtension",
            targets: ["SwiftAlamofireExtension"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/hcmc-studio/swift-protocol-extension.git",
            branch: "0.0.58"
        ),
        .package(
            url: "https://github.com/hcmc-studio/swift-type-extension",
            branch: "0.0.58"
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
