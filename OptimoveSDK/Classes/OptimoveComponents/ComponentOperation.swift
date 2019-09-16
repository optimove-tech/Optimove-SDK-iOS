//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol ComponentOperation { }

protocol OperationContext {
    /// The timestamp of a creation if this context.
    var timestamp: TimeInterval { get set }
    associatedtype Operation: ComponentOperation
    var operation: Operation { get set }
}

final class EventableOperationContext: OperationContext {
    var timestamp: TimeInterval
    var operation: EventableOperation

    init(_ operation: EventableOperation, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.operation = operation
        self.timestamp = timestamp
    }

}

enum EventableOperation: ComponentOperation {
    case setUserId(userId: String)
    case report(event: OptimoveEvent)
    case reportScreenEvent(customURL: String, pageTitle: String, category: String?)
    case dispatchNow
}

final class PushableOperationContext: OperationContext {
    var timestamp: TimeInterval
    var operation: PushableOperation

    init(_ operation: PushableOperation, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.operation = operation
        self.timestamp = timestamp
    }

}

enum PushableOperation: ComponentOperation {
    case deviceToken(token: Data)
    case performRegistration
    case unsubscribeFromTopic(topic: String)
    case subscribeToTopic(topic: String)
    case optIn
    case optOut
}
