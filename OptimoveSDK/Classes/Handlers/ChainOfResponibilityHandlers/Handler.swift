//  Copyright © 2019 Optimove. All rights reserved.

class Node<OC: OperationContext> {
    var next: Node<OC>?
    func execute(_: OC) throws {
        fatalError("No implementation. Expect to be implemented by inheretance.")
    }
}

class EventableNode: Node<EventableOperationContext> { }

class PushableNode: Node<PushableOperationContext> {}

