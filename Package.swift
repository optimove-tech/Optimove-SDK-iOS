// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Optimove",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "OptimoveSDK",
            type: .dynamic,
            targets: ["OptimoveSDK"]
        ),
        .library(
            name: "OptimoveCore",
            type: .dynamic,
            targets: ["OptimoveCore"]
        ),
        .library(
            name: "OptimoveNotificationServiceExtension",
            type: .dynamic,
            targets: ["OptimoveNotificationServiceExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/matomo-org/matomo-sdk-ios.git", from: "7.2.0"),
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.0.2"),
    ],
    targets: [
        .target(
            name: "OptimoveSDK",
            dependencies: [
                "OptimoveCore",
                "MatomoTracker",
            ],
            path: "OptimoveSDK/Sources"
        ),
        .testTarget(
            name: "OptimoveSDK-Unit",
            dependencies: [
                "OptimoveSDK",
                "Mocker"
            ],
            path: "OptimoveSDK/Tests",
            sources: [
                "Shared/Tests",
            ]
        ),
        .target(
            name: "OptimoveCore",
            path: "OptimoveCore/Sources"
        ),
        .testTarget(
            name: "OptimoveCore-Unit",
            dependencies: [
                "OptimoveCore"
            ],
            path: "OptimoveCore/Tests",
            sources: [
                "Shared/Tests",
            ]
        ),
        .target(
            name: "OptimoveNotificationServiceExtension",
            dependencies: [
                "OptimoveCore"
            ],
            path: "OptimoveNotificationServiceExtension/Sources"
        ),
        .testTarget(
            name: "OptimoveNotificationServiceExtension-Unit",
            dependencies: [
                "OptimoveNotificationServiceExtension"
            ],
            path: "OptimoveNotificationServiceExtension/Tests",
            sources: [
                "Shared/Tests",
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
