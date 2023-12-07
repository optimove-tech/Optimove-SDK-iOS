//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension String {
    /// Returns a random string from a set of aliphanumeric characters.
    /// https://stackoverflow.com/a/26845710
    ///
    /// - Parameter length: The lenght of a generated string.
    /// - Returns: The random generated string.
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }
}
