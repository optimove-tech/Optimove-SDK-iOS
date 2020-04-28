//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public extension Bundle {

    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "undefined"
    }

}
