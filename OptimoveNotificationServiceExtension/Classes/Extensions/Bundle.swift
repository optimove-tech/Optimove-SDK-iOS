// Copiright 2019 Optimove

import Foundation

extension Bundle {
    
    static func extractHostAppBundle() -> Bundle? {
        let mainBundle = Bundle.main
        if mainBundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - SOME_APP.app/PlugIns/SOME_APP_EXTENSION.appex
            let url = mainBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let hostBundle = Bundle(url: url) {
                return hostBundle
            }
        }
        return nil
    }
    
}
