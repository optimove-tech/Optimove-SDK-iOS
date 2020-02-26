//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class OperationContext {
    /// The timestamp of a creation if this context.
    let timestamp: TimeInterval
    let operation: Operation

    init(operation: Operation, timestamp: TimeInterval) {
        self.operation = operation
        self.timestamp = timestamp
    }

    convenience init(_ operation: Operation) {
        self.init(operation: operation, timestamp: Date().timeIntervalSince1970)
    }

}

enum Operation {
    case setUserId
    case enablePushCampaigns
    case disablePushCampaigns
    case report(event: OptimoveEvent)
    case reportScreenEvent(title: String, category: String?)
    case dispatchNow
    case deviceToken(token: Data)
    case optIn
    case optOut
}
