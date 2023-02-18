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
    dependencies: [
        .package(url: "https://github.com/0xLeif/Fork", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "Plugin",
            dependencies: ["Fork"]
        ),
        .testTarget(
            name: "PluginTests",
            dependencies: ["Plugin"]
        )
    ]
)
