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
            name: "SwiftProtocolExtension",
            url: "https://github.com/hcmc-studio/swift-protocol-extension.git",
            branch: "0.0.55"
        ),
        .package(
            name: "SwiftTypeExtension",
            url: "https://github.com/hcmc-studio/swift-type-extension",
            branch: "0.0.55"
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire",
            .upToNextMajor(from: "5.8.0")
        ),
        .package(
            name: "Algorithms",
            url: "https://github.com/apple/swift-algorithms.git",
            .upToNextMajor(from: "1.1.0")
        ),
        .package(
            url: "https://github.com/SwiftyJSON/SwiftyJSON.git",
            .upToNextMajor(from: "5.0.1")
        ),
    ],
    targets: [
        .target(
            name: "SwiftAlamofireExtension",
            dependencies: ["SwiftProtocolExtension", "SwiftTypeExtension", "Alamofire", "Algorithms", "SwiftyJSON"]
        ),
        .testTarget(
            name: "SwiftAlamofireExtensionTests",
            dependencies: ["SwiftAlamofireExtension"]
        ),
    ]
)
