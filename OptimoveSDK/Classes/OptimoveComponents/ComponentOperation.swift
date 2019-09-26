//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

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
    case eventable(EventableOperation)
    case pushable(PushableOperation)
}

enum EventableOperation {
    case setUserId(userId: String)
    case report(event: OptimoveEvent)
    case reportScreenEvent(customURL: String, pageTitle: String, category: String?)
    case dispatchNow
}

enum PushableOperation {
    case deviceToken(token: Data)
    case subscribeToTopic(topic: String)
    case unsubscribeFromTopic(topic: String)
    case migrateUser
    case optIn
    case optOut
}
