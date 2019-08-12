//  Copyright © 2019 Optimove. All rights reserved.

public protocol OptimoveEvent {
    var name: String { get }
    var parameters: [String: Any] { get }
}
