// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "base-cli",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "base", targets: ["BaseCLI"])
    ],
    targets: [
        .executableTarget(
            name: "BaseCLI"
        ),
        .testTarget(
            name: "BaseCLITests",
            dependencies: ["BaseCLI"]
        )
    ]
)
