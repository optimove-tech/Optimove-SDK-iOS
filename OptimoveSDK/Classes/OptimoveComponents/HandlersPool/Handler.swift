//  Copyright © 2019 Optimove. All rights reserved.

protocol Handler {

    associatedtype HandlerInstance: Handler
    var next: HandlerInstance? { get set }

    associatedtype HandlerOperationContext: OperationContext
    func handle(_: HandlerOperationContext) throws

}

class EventableHandler: Handler {
    typealias HandlerInstance = EventableHandler
    typealias HandlerOperationContext = EventableOperationContext

    var next: EventableHandler?

    func handle(_: EventableOperationContext) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }

}

class PushableHandler: Handler {
    typealias HandlerInstance = PushableHandler
    typealias HandlerOperationContext = PushableOperationContext

    var next: PushableHandler?

    func handle(_: PushableOperationContext) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }
}

