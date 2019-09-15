//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension Bundle {

    /// https://stackoverflow.com/a/27849695
    static func hostAppBundle() -> Bundle? {
        let mainBundle = Bundle.main
        if mainBundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - SOME_APP.app/PlugIns/SOME_APP_EXTENSION.appex
            let url = mainBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let hostBundle = Bundle(url: url) {
                return hostBundle
            }
        }
        return mainBundle
    }

}
