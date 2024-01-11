// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQift",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "SQift",
            targets: ["SQift"]
        ),
    ],
    targets: [
        .target(
            name: "SQift",
            path: "Source",
            exclude: ["Supporting Files"]
        ),
        .testTarget(
            name: "SQiftTests",
            dependencies: ["SQift"],
            path: "Tests",
            exclude: ["Supporting Files"]
        )
    ]
)
