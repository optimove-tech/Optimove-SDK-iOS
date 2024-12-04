//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

public extension Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    /// The issue described [here](https://forums.swift.org/t/swift-5-3-spm-resources-in-tests-uses-wrong-bundle-path/37051/47)
    static let mypackageResources: Bundle = {
        #if DEBUG
            if let moduleName = Bundle(for: BundleFinder.self).bundleIdentifier,
               let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"]
            {
                if let lastModuleComponent = moduleName.components(separatedBy: ".").last, let resourceBundle = Bundle(path: testBundlePath + "/Optimove_\(lastModuleComponent).bundle") {
                    return resourceBundle
                }
            }
        #endif
        return Bundle.module
    }()

    private final class BundleFinder {}
}
