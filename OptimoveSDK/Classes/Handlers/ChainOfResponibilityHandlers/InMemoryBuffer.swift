//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InMemoryBuffer<OC: OperationContext>: Handler<OC> {

    private var buffer = RingBuffer<OC>(count: 100)
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    override var next: Handler<OC>? {
        didSet {
            dispatchBuffer()
        }
    }

    override func handle(_ context: OC) throws {
        if next == nil {
            var context = context
            context.isBuffered = true
            buffer.write(context)
        } else {
            try next?.handle(context)
        }
    }

    private func dispatchBuffer() {
        while let context = buffer.read() {
            do {
                try next?.handle(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
