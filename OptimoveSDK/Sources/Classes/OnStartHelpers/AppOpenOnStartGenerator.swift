//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit.UIApplication

final class AppOpenOnStartGenerator {

    private let synchronizer: Synchronizer
    private let coreEventFactory: CoreEventFactory

    init(synchronizer: Synchronizer,
         coreEventFactory: CoreEventFactory) {
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.generate()
            }
            return
        }
        guard UIApplication.shared.applicationState != .background else { return }
        tryCatch {
            let event = try coreEventFactory.createEvent(.appOpen)
            self.synchronizer.handle(.report(events: [event]))
        }
    }

}
