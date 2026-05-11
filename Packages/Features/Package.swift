// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Features",
    defaultLocalization: "pl",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedFeature", targets: ["SharedFeature"]),
        .library(name: "ClientFeature", targets: ["ClientFeature"]),
        .library(name: "InstructorFeature", targets: ["InstructorFeature"]),
        .library(name: "GroomFeature", targets: ["GroomFeature"]),
        .library(name: "ManagerFeature", targets: ["ManagerFeature"]),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core"),
    ],
    targets: [
        .target(
            name: "SharedFeature",
            dependencies: [
                .product(name: "CoreDesignSystem", package: "Core"),
                .product(name: "CoreAuth", package: "Core"),
                .product(name: "CoreNetworking", package: "Core"),
                .product(name: "CoreSync", package: "Core"),
            ],
            path: "Sources/SharedFeature"
        ),
        .target(
            name: "ClientFeature",
            dependencies: [
                "SharedFeature",
                .product(name: "CorePersistence", package: "Core"),
            ],
            path: "Sources/ClientFeature"
        ),
        .target(
            name: "InstructorFeature",
            dependencies: ["SharedFeature"],
            path: "Sources/InstructorFeature"
        ),
        .target(
            name: "GroomFeature",
            dependencies: [
                "SharedFeature",
                .product(name: "CorePersistence", package: "Core"),
                .product(name: "CoreSync", package: "Core"),
            ],
            path: "Sources/GroomFeature"
        ),
        .target(
            name: "ManagerFeature",
            dependencies: ["SharedFeature"],
            path: "Sources/ManagerFeature"
        ),
    ]
)
