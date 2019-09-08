//  Copyright © 2019 Optimove. All rights reserved.

struct VisitorIDPreprocessor {

    /// Produce a 16 characters string represents the visitor ID of the client
    ///
    /// - Parameter userId: The user ID which is the source
    /// - Returns: THe generated visitor ID
    static func process(_ userId: String) -> String {
        return userId.sha1().prefix(16).description.lowercased()
    }
}
