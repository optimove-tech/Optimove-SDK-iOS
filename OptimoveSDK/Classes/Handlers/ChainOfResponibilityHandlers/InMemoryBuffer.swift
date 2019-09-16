//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InMemoryBuffer<OC: OperationContext>: Node<OC> {

    private var buffer = RingBuffer<OC>(count: 100)
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    override var next: Node<OC>? {
        didSet {
            dispatchBuffer()
        }
    }

    override func execute(_ context: OC) throws {
        if next == nil {
            var context = context
            context.timestamp = Date().timeIntervalSince1970
            buffer.write(context)
        } else {
            try next?.execute(context)
        }
    }

    private func dispatchBuffer() {
        while let context = buffer.read() {
            do {
                try next?.execute(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
