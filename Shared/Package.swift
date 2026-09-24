// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KipirShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KipirShared", targets: ["KipirShared"]),
    ],
    targets: [
        .target(name: "KipirShared"),
        .testTarget(name: "KipirSharedTests", dependencies: ["KipirShared"]),
    ]
)
