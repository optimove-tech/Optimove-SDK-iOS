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
            type: .static,
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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.0.2")
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
            dependencies: [
                "OptimoveCore"
            ],
            path: "OptimoveNotificationServiceExtension/Sources"
        )
    ],
    swiftLanguageVersions: [.v5]
)
