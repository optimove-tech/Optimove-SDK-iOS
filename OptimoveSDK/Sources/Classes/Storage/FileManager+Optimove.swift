//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

private var temporaryDirectoryURL: URL?

extension FileManager {
    static func optimoveURL() throws -> URL {
        return try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static func temporaryURL() throws -> URL {
        if let temporaryDirectoryURL = temporaryDirectoryURL {
            return temporaryDirectoryURL
        }
        temporaryDirectoryURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: URL(
                fileURLWithPath: NSTemporaryDirectory(),
                isDirectory: true
            ),
            create: true
        )
        return try temporaryURL()
    }
}
