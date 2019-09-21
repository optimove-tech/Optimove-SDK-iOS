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
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState != .background else { return }
            tryCatch {
                self.synchronizer.handle(
                    .report(
                        event: try self.coreEventFactory.createEvent(.appOpen)
                    )
                )
            }
        }
    }

}

