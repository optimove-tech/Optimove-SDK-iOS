//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit.UIApplication

final class OnStartEventGenerator {

    private let coreEventFactory: CoreEventFactory

    init(coreEventFactory: CoreEventFactory) {
        self.coreEventFactory = coreEventFactory
    }

    func generate() throws -> [OptimoveEvent] {
        return [
            try coreEventFactory.createEvent(.setUserAgent),
            try coreEventFactory.createEvent(.metaData),
            try coreEventFactory.createEvent(.setAdvertisingId),
            reportAppOpened()
        ].compactMap { $0 }
    }

    func reportAppOpened() -> OptimoveEvent? {
        guard UIApplication.shared.applicationState != .background else { return nil }
        do {
            return try coreEventFactory.createEvent(.appOpen)
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }

}

