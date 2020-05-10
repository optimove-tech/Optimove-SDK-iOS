//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InMemoryBuffer: Node {

    private var buffer = RingBuffer<CommonOperation>(count: 100)

    override var next: Node? {
        didSet {
            dispatchBuffer()
        }
    }

    override func execute(_ operation: CommonOperation) throws {
        if next == nil {
            buffer.write(operation)
        } else {
            try next?.execute(operation)
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
