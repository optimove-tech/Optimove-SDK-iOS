//  Copyright © 2019 Optimove. All rights reserved.

protocol OptimoveEvent {
    var name: String { get }
    var parameters: [String: Any] { get }
}
