//  Copyright © 2019 Optimove. All rights reserved.

class Handler<OC: OperationContext> {
    var next: Handler<OC>?
    func handle(_: OC) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }
}

class EventableHandler: Handler<EventableOperationContext> { }

class PushableHandler: Handler<PushableOperationContext> {}

