//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Synchronizer {
    func handle(_: EventableOperation)
    func handle(_: PushableOperation)
}

final class SynchronizerImpl {

    private let queue: DispatchQueue
    private let chain: Chain

    init(chain: Chain) {
        self.chain = chain
        queue = DispatchQueue(label: "com.optimove.sdk.synchronizer", qos: .utility)
    }
}

extension SynchronizerImpl: Synchronizer {

    func handle(_ operation: EventableOperation) {
        queue.async { [chain] in
            tryCatch {
                try chain.next.execute(.init(.eventable(operation)))
            }
        }
    }

    func handle(_ operation: PushableOperation) {
        queue.async { [chain] in
            tryCatch {
                try chain.next.execute(.init(.pushable(operation)))
            }
        }
    }

}
