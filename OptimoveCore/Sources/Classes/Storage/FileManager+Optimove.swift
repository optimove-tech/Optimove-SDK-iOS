//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public extension FileManager {

    static func optimoveURL() throws -> URL {
        return try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
}
