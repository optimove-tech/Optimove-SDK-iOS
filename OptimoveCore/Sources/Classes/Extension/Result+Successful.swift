//  Copyright © 2019 Optimove. All rights reserved.

public extension Result {
    var isSuccessful: Bool {
        do {
            _ = try get()
            return true
        } catch {
            return false
        }
    }
}
