//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public extension ProcessInfo {
    var osVersion: String {
        [
            operatingSystemVersion.majorVersion,
            operatingSystemVersion.minorVersion,
            operatingSystemVersion.patchVersion,
        ].map { String($0) }.joined(separator: ".")
    }
}
