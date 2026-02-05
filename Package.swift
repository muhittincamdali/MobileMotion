// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MobileMotion",
    platforms: [
        .iOS(.v15)
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
            path: "Sources/MobileMotion",
            linkerSettings: [
                .linkedFramework("CoreMotion"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("UIKit", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "MobileMotionTests",
            dependencies: ["MobileMotion"],
            path: "Tests/MobileMotionTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
