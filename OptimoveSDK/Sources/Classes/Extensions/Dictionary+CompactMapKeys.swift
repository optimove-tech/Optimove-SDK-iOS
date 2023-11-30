//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        return try reduce(into: [T: Value]()) { result, x in
            if let key = try transform(x.key) {
                result[key] = x.value
            }
        }
    }
}
