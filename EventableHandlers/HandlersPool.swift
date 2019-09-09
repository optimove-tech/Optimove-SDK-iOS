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
