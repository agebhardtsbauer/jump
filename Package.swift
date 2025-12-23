// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Jump",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "Jump",
            targets: ["Jump"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Jump",
            dependencies: [],
            path: "Sources/Jump"
        )
    ]
)
