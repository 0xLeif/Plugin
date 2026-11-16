// swift-tools-version: 6.0
// Tools version 6.0 builds every target in the Swift 6 language mode (complete data-race checking).

import PackageDescription

let package = Package(
    name: "Plugin",
    // The floor is set by parameterized protocol existentials (`any Plugin<Input, Output>`),
    // which need the Swift 5.7 runtime, and by `OSAllocatedUnfairLock`, which guards the
    // plugin list without an `@unchecked Sendable` conformance. Both arrived in the same releases.
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
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
