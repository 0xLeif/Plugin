// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Plugin",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Plugin",
            targets: ["Plugin"]
        )
    ],
    targets: [
        .target(name: "Plugin"),
        .testTarget(
            name: "PluginTests",
            dependencies: ["Plugin"]
        )
    ]
)
