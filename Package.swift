// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Optimove",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "OptimoveSDK",
            targets: ["OptimoveSDK"]
        ),
        .library(
            name: "OptimoveCore",
            targets: ["OptimoveCore"]
        ),
        .library(
            name: "OptimoveNotificationServiceExtension",
            targets: ["OptimoveNotificationServiceExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker", from: "3.0.1"),
    ],
    targets: [
        .target(
            name: "OptimoveSDK",
            dependencies: [
                "OptimobileCore",
                "OptimoveCore",
            ],
            path: "OptimoveSDK/Sources"
        ),
        .target(
            name: "OptimoveCore",
            path: "OptimoveCore/Sources"
        ),
        .target(
            name: "OptimobileCore",
            path: "OptimobileCore/Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "OptimoveNotificationServiceExtension",
            dependencies: [
                "OptimobileCore",
            ],
            path: "OptimoveNotificationServiceExtension/Sources"
        ),
        .target(
            name: "OptimoveTest",
            dependencies: [
                "OptimoveCore",
            ],
            path: "Shared",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OptimoveSDKTests",
            dependencies: [
                "Mocker",
                "OptimoveSDK",
                "OptimoveTest",
            ],
            path: "OptimoveSDK/Tests",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OptimoveCoreTests",
            dependencies: [
                "Mocker",
                "OptimoveCore",
                "OptimoveTest",
            ],
            path: "OptimoveCore/Tests",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OptimobileCoreTests",
            dependencies: [
                "OptimobileCore",
                "OptimoveTest",
            ],
            path: "OptimobileCore/Tests",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "OptimoveNotificationServiceExtensionTests",
            dependencies: [
                "OptimoveNotificationServiceExtension",
                "OptimoveTest",
            ],
            path: "OptimoveNotificationServiceExtension/Tests",
            resources: [
                .process("Resources"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
