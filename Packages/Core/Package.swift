// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Core",
    defaultLocalization: "pl",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "CorePersistence", targets: ["CorePersistence"]),
        .library(name: "CoreSync", targets: ["CoreSync"]),
        .library(name: "CoreAuth", targets: ["CoreAuth"]),
        .library(name: "CoreDesignSystem", targets: ["CoreDesignSystem"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.29.0"),
    ],
    targets: [
        .target(name: "CoreDesignSystem", path: "Sources/CoreDesignSystem"),
        .target(
            name: "CoreNetworking",
            dependencies: ["CoreAuth"],
            path: "Sources/CoreNetworking"
        ),
        .target(
            name: "CorePersistence",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            path: "Sources/CorePersistence"
        ),
        .target(
            name: "CoreAuth",
            path: "Sources/CoreAuth"
        ),
        .target(
            name: "CoreSync",
            dependencies: [
                "CoreNetworking", "CorePersistence", "CoreAuth",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/CoreSync"
        ),
    ]
)
