//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit.UIApplication

final class AppOpenOnStartGenerator {

    private let handler: HandlersPool
    private let coreEventFactory: CoreEventFactory

    init(handler: HandlersPool,
         coreEventFactory: CoreEventFactory) {
        self.handler = handler
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState != .background else { return }
            tryCatch {
                try self.handler.eventableHandler.handle(.init(.report(
                    event: try self.coreEventFactory.createEvent(.appOpen)))
                )
            }
        }
    }

}

