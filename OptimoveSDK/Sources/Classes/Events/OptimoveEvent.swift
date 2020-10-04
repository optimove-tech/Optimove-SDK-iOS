//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public protocol OptimoveEvent {
    @objc var name: String { get }
    /// Valid a parameter values are `String`, `Int`, `Float`, `Double` or `Boolean`.
    @objc var parameters: [String: Any] { get }
}
