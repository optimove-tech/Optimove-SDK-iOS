//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import Foundation

enum HandlerType: Equatable {
    case eventable(EventableType)
    case pushable

    enum EventableType: Equatable {
        case realtime
        case tracker
    }
}

protocol Handler {
    associatedtype HandlerInstance: Handler
    var nextHandler: HandlerInstance? { get set }
    @discardableResult
    mutating func setNext(_: HandlerInstance) -> HandlerInstance
    associatedtype HandlerOperation: OperationContext
    func handle(_: HandlerOperation) throws
}

extension Handler {
    @discardableResult
    mutating func setNext(_ handler: HandlerInstance) -> HandlerInstance {
        nextHandler = handler
        return handler
    }
}

class EventableHandler: Handler {
    typealias HandlerInstance = EventableHandler
    typealias HandlerOperation = EventableOperationContext

    var nextHandler: EventableHandler?

    func handle(_: EventableOperationContext) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }

}

class PushableHandler: Handler {
    typealias HandlerInstance = PushableHandler
    typealias HandlerOperation = PushableOperationContext

    var nextHandler: PushableHandler?

    func handle(_: PushableOperationContext) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }
}

