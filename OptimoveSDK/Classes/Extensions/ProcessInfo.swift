// Copiright 2019 Optimove

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
