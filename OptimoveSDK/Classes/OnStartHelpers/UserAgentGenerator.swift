//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class UserAgentGenerator {

    private var storage: OptimoveStorage
    private let handler: HandlersPool
    private let coreEventFactory: CoreEventFactory

    init(storage: OptimoveStorage,
         handler: HandlersPool,
         coreEventFactory: CoreEventFactory) {
        self.storage = storage
        self.handler = handler
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        SDKDevice.evaluateUserAgent(completion: { (userAgent) in
            self.storage.userAgent = userAgent
            tryCatch {
                try self.handler.eventableHandler.handle(
                    EventableOperationContext(.report(event: try self.coreEventFactory.createEvent(.setUserAgent)))
                )
            }
        })
    }

}
