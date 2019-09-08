//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InMemoryEventableBuffer: EventableHandler {

    private var buffer = RingBuffer<EventableOperationContext>(count: 100)
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func setNext(_ handler: EventableHandler) -> EventableHandler {
        self.next = handler
        dispatchBuffer()
        return handler
    }

    override func handle(_ context: EventableOperationContext) throws {
        handleSpecialCases(context)
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

    func handleSpecialCases(_ context: EventableOperationContext) {
        switch context.operation {
        case let .report(event: event):
            if next == nil {
                if event.name == OptimoveKeys.Configuration.setUserId.rawValue {
                    storage.realtimeSetUserIdFailed = true
                } else if event.name == OptimoveKeys.Configuration.setEmail.rawValue {
                    storage.realtimeSetEmailFailed = true
                }
            }
        default:
            break
        }
    }

}

final class InMemoryPushableBuffer: PushableHandler {

    private var buffer = RingBuffer<PushableOperationContext>(count: 100)
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

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
