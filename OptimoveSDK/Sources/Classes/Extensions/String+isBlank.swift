//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension String {
    /// Returns timmed string without whitespaces and new lines.
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
