//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class HandlersPool {

    private(set) var eventableHandler: Handler<EventableOperationContext>
    private(set) var pushableHandler: Handler<PushableOperationContext>

    init(eventableHandler: Handler<EventableOperationContext>,
         pushableHandler: Handler<PushableOperationContext>) {
        self.eventableHandler = eventableHandler
        self.pushableHandler = pushableHandler
    }

    func addNextEventableHandler(_ next: EventableHandler) {
        eventableHandler.next = next
    }

    func addNextPushableHandler(_ next: PushableHandler) {
        pushableHandler.next = next
    }

}

extension HandlersPool: ResignActiveSubscriber {

    func onResignActive() {
        do {
            try eventableHandler.handle(.init(.dispatchNow))
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}

final class Synchronizer {

    private let queue: DispatchQueue
    private let handler: HandlersPool

    init(handler: HandlersPool) {
        self.handler = handler
        queue = DispatchQueue(label: "com.optimove.sdk.synchronizer", qos: .utility)
    }

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
