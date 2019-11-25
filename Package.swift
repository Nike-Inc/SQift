// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SQift",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12),
        .tvOS(.v10),
        .watchOS(.v3),
    ],
    products: [
        .library(
            name: "SQift",
            targets: ["SQift"]),
    ],
    targets: [
        .target(
            name: "SQift",
            path: "Source"),
        .testTarget(
            name: "SQiftTests",
            dependencies: ["SQift"],
            path: "Tests"),
    ]
)
