//  Copyright © 2019 Optimove. All rights reserved.

import Dispatch
import OptimoveCore

/// Use for executing a internal operation flow with serial queue.
protocol Synchronizer: ChainMutator, ResignActiveSubscriber {
    func handle(_: Operation)
}

final class SynchronizerImpl {

    private let queue: DispatchQueue
    private let chain: Chain

    init(chain: Chain) {
        queue = DispatchQueue(label: "com.optimove.synchronizer", qos: .utility)
        self.chain = chain
    }

}

extension SynchronizerImpl: Synchronizer {

    func handle(_ operation: Operation) {
        queue.async { [chain] in
            tryCatch {
                try chain.next.execute(.init(operation))
            }
        }
    }

}

extension SynchronizerImpl: ChainMutator {

    func addNode(_ node: Node) {
        queue.async { [chain] in
            chain.next.next = node
        }
    }

}

extension SynchronizerImpl: ResignActiveSubscriber {

    func onResignActive() {
        handle(.dispatchNow)
    }

}
