//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class InMemoryEventableBuffer: EventableHandler {

    private var buffer = RingBuffer<EventableOperation>(count: 100)

    override func handle(_ operation: EventableOperation) throws {
        if nextHandler == nil {
            buffer.write(operation)
        } else {
            dispatchBuffer()
            try nextHandler?.handle(operation)
        }
    }

    func dispatchBuffer() {
        while let operation = buffer.read() {
            try? nextHandler?.handle(operation)
        }
    }

}

final class InMemoryPushableBuffer: PushableHandler {

    private var buffer = RingBuffer<PushableOperation>(count: 100)

    override func handle(_ operation: PushableOperation) throws {
        if nextHandler == nil {
            buffer.write(operation)
        } else {
            dispatchBuffer()
            try nextHandler?.handle(operation)
        }
    }

    func dispatchBuffer() {
        while let operation = buffer.read() {
            try? nextHandler?.handle(operation)
        }
    }

}
