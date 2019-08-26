//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension ProcessInfo {
    var operatingSystemVersionOnlyString: String {
        return [
            operatingSystemVersion.majorVersion,
            operatingSystemVersion.minorVersion,
            operatingSystemVersion.patchVersion
        ].map { String($0) }.joined(separator: ".")
    }
}
