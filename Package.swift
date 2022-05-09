// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Optimove",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_14)
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
        )
    ],
    targets: [
        .target(
            name: "OptimoveSDK",
            dependencies: [
                "OptimoveCore"
            ],
            path: "OptimoveSDK/Sources"
        ),
        .target(
            name: "OptimoveCore",
            path: "OptimoveCore/Sources"
        ),
        .target(
            name: "OptimoveNotificationServiceExtension",
            path: "OptimoveNotificationServiceExtension/Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
