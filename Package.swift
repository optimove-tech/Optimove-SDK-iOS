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
                "OptimoveCore",
            ],
            path: "OptimoveSDK/Sources"
        ),
        .target(
            name: "OptimoveCore",
            path: "OptimoveCore/Sources"
        ),
        .target(
            name: "OptimoveNotificationServiceExtension",
            dependencies: [
                "OptimoveCore",
            ],
            path: "OptimoveNotificationServiceExtension/Sources"
        ),
        .target(
            name: "OptimoveTest",
            dependencies: [
                "OptimoveSDK",
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
            name: "OptimoveNotificationServiceExtensionTests",
            dependencies: [
                "OptimoveNotificationServiceExtension",
                "OptimoveTest",
            ],
            path: "OptimoveNotificationServiceExtension/Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
