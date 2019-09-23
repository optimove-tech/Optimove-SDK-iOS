//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class UserAgentGenerator {

    private var storage: OptimoveStorage
    private let synchronizer: Synchronizer
    private let coreEventFactory: CoreEventFactory

    init(storage: OptimoveStorage,
         synchronizer: Synchronizer,
         coreEventFactory: CoreEventFactory) {
        self.storage = storage
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        SDKDevice.evaluateUserAgent(completion: { (userAgent) in
            self.storage.userAgent = userAgent
            tryCatch {
                self.synchronizer.handle(
                    .report(event: try self.coreEventFactory.createEvent(.setUserAgent))
                )
            }
        })
    }

}
