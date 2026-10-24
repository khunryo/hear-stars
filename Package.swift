// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HearStarsCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HearStarsCore", targets: ["HearStarsCore"])
    ],
    targets: [
        .target(
            name: "HearStarsCore",
            path: "Sources/HearStarsCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "HearStarsCoreTests",
            dependencies: ["HearStarsCore"],
            path: "Tests/HearStarsCoreTests"
        )
    ]
)

