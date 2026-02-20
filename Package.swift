// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TelbisesAIDealScout",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "TelbisesAIDealScout", targets: ["TelbisesAIDealScout"])
    ],
    targets: [
        .target(
            name: "TelbisesAIDealScout",
            path: "Sources/TelbisesAIDealScout",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TelbisesAIDealScoutTests",
            dependencies: ["TelbisesAIDealScout"],
            path: "Tests/TelbisesAIDealScoutTests"
        )
    ]
)
