//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InMemoryBuffer: Pipe {

    private var buffer = RingBuffer<CommonOperation>(count: 100)

    override var next: Pipe? {
        didSet {
            dispatchBuffer()
        }
    }

    override func deliver(_ operation: CommonOperation) throws {
        guard let next = next else {
            buffer.write(operation)
            return
        }
        try next.deliver(operation)
    }

    private func dispatchBuffer() {
        while let context = buffer.read() {
            do {
                try next?.deliver(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
