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

    @discardableResult
    func addNextEventableHandler(_ nextHandler: EventableHandler) -> EventableHandler {
        return eventableHandler.setNext(nextHandler)
    }

    @discardableResult
    func addNextPushableHandler(_ nextHandler: PushableHandler) -> PushableHandler {
        return pushableHandler.setNext(nextHandler)
    }

}
