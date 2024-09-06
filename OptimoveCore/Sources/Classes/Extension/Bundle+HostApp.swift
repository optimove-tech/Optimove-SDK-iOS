//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension Bundle {
    /// Returns the bundle containing the host app.
    /// https://stackoverflow.com/a/27849695
    static func hostAppBundle() -> Bundle {
        let mainBundle = Bundle.main
        if mainBundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - APP.app/PlugIns/APP_EXTENSION.appex
            let url = mainBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let hostBundle = Bundle(url: url) {
                return hostBundle
            }
        }
        return mainBundle
    }

    /// Returns the bundle identifier of the host app.
    static var hostAppBundleIdentifier: String {
        return hostAppBundle().bundleIdentifier!
    }

    /// Returns the app group identifier for the SDK app.
    static var optimoveAppGroupIdentifier: String {
        return "group.\(hostAppBundleIdentifier).optimove"
    }
}
