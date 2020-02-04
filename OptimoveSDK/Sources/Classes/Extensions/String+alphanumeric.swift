//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension String {

    /// Returns trimmed string without non-alphanumerics characters.
    /// https://stackoverflow.com/a/52052475
    var alphanumeric: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined().lowercased()
    }

}
