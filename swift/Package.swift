// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MobileMotion",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "MobileMotion",
            targets: ["MobileMotion"]
        )
    ],
    targets: [
        .target(
            name: "MobileMotion",
            path: "Sources/MobileMotion"
        ),
        .testTarget(
            name: "MobileMotionTests",
            dependencies: ["MobileMotion"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
