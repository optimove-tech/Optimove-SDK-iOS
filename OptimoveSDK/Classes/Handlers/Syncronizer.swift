//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Synchronizer {
    func handle(_: EventableOperation)
    func handle(_: PushableOperation)
}

final class SynchronizerImpl {

    private let queue: DispatchQueue
    private let chain: ChainPool

    init(chain: ChainPool) {
        self.chain = chain
        queue = DispatchQueue(label: "com.optimove.sdk.synchronizer", qos: .utility)
    }
}

extension SynchronizerImpl: Synchronizer {

    func handle(_ operation: EventableOperation) {
        queue.async { [chain] in
            tryCatch {
                try chain.eventableNode.execute(EventableOperationContext(operation))
            }
        }
    }

    func handle(_ operation: PushableOperation) {
        queue.async { [chain] in
            tryCatch {
                try chain.pushableNode.execute(PushableOperationContext(operation))
            }
        }
    }

}
