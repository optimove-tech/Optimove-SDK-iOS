//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public extension ProcessInfo {

    var osVersion: String {
        [
            self.operatingSystemVersion.majorVersion,
            self.operatingSystemVersion.minorVersion,
            self.operatingSystemVersion.patchVersion
        ].map { String($0) }.joined(separator: ".")
    }
}

