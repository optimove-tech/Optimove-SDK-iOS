//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class UserAgentGenerator {
    private var storage: OptimoveStorage
    private let synchronizer: Pipeline
    private let coreEventFactory: CoreEventFactory

    init(storage: OptimoveStorage,
         synchronizer: Pipeline,
         coreEventFactory: CoreEventFactory)
    {
        self.storage = storage
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        func generateUserAgent() -> String {
            let deviceName = UIDevice.current.model
            let osName = UIDevice.current.systemName
            let osVersion = UIDevice.current.systemVersion
            let locale = Locale.current.identifier
            let timeZone = TimeZone.current.identifier

            return "\(deviceName); \(osName) \(osVersion); \(locale); \(timeZone)"
        }
        self.storage.userAgent = generateUserAgent()
        tryCatch {
            let event = try self.coreEventFactory.createEvent(.setUserAgent)
            self.synchronizer.deliver(.report(events: [event]))
        }
    }
}
