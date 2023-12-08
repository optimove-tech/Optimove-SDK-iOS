//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

extension Bundle {
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "undefined"
    }
}
