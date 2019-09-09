//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol ComponentOperation { }

protocol OperationContext {
    var isBuffered: Bool { get set }
    associatedtype Operation: ComponentOperation
    var operation: Operation { get set }
}

final class EventableOperationContext: OperationContext {
    var isBuffered: Bool
    var operation: EventableOperation

    init(_ operation: EventableOperation, isBuffered: Bool = false) {
        self.operation = operation
        self.isBuffered = isBuffered
    }

}

enum EventableOperation: ComponentOperation {
    case setUserId(userId: String)
    case report(event: OptimoveEvent)
    case reportScreenEvent(customURL: String, pageTitle: String, category: String?)
    case dispatchNow
}

final class PushableOperationContext: OperationContext {
    var isBuffered: Bool
    var operation: PushableOperation

    init(_ operation: PushableOperation, isBuffered: Bool = false) {
        self.operation = operation
        self.isBuffered = isBuffered
    }

}

enum PushableOperation: ComponentOperation {
    case deviceToken(token: Data)
    case performRegistration
    case unsubscribeFromTopic(topic: String)
    case subscribeToTopic(topic: String)
}
