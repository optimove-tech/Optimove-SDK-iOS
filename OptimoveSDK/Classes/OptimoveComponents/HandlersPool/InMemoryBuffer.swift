//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class InMemoryEventableBuffer: EventableHandler {

    private var buffer = RingBuffer<EventableOperationContext>(count: 100)

    func setNext(_ handler: EventableHandler) -> EventableHandler {
        self.next = handler
        dispatchBuffer()
        return handler
    }

    override func handle(_ context: EventableOperationContext) throws {
        if next == nil {
            buffer.write(context)
        } else {
            try next?.handle(context)
        }
    }

    func dispatchBuffer() {
        while let context = buffer.read() {
            try? next?.handle(context)
        }
    }

}

final class InMemoryPushableBuffer: PushableHandler {

    private var buffer = RingBuffer<PushableOperationContext>(count: 100)

    func setNext(_ handler: PushableHandler) -> PushableHandler {
        self.next = handler
        dispatchBuffer()
        return handler
    }

    override func handle(_ context: PushableOperationContext) throws {
        if next == nil {
            context.isBuffered = true
            buffer.write(context)
        } else {
            try next?.handle(context)
        }
    }

    func dispatchBuffer() {
        while let context = buffer.read() {
            try? next?.handle(context)
        }
    }

}
