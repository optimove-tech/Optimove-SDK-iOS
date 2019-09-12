//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Synchronizer {
    func handle(_: EventableOperation)
    func handle(_: PushableOperation)
}

final class SynchronizerImpl {

    private let queue: DispatchQueue
    private let handler: HandlersPool

    init(handler: HandlersPool) {
        self.handler = handler
        queue = DispatchQueue(label: "com.optimove.sdk.synchronizer", qos: .utility)
    }
}

extension SynchronizerImpl: Synchronizer {

    func handle(_ operation: EventableOperation) {
        queue.async { [handler] in
            tryCatch {
                try handler.eventableHandler.handle(EventableOperationContext(operation))
            }
        }
    }

    func handle(_ operation: PushableOperation) {
        queue.async { [handler] in
            tryCatch {
                try handler.pushableHandler.handle(PushableOperationContext(operation))
            }
        }
    }

}
