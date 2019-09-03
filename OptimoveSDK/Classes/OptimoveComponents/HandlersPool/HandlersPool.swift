//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class HandlersPool {

    private(set) var eventableHandler: EventableHandler
    private(set) var pushableHandler: PushableHandler

    init(eventableHandler: EventableHandler,
         pushableHandler: PushableHandler) {
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
