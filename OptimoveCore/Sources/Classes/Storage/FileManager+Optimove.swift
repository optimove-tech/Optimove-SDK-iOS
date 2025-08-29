//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension FileManager {
    static func optimoveURL() throws -> URL {
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return url
        }
        if let fallback = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return fallback
        }
        return FileManager.default.temporaryDirectory
    }

    static func temporaryURL() throws -> URL {
        return FileManager.default.temporaryDirectory
    }
}
