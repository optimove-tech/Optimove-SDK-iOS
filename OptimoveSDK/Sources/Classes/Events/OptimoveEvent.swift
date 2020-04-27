//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public protocol OptimoveEvent {
    @objc var name: String { get }
    @objc var parameters: [String: Any] { get }
}
