//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class LoggerInitializator {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func initialize() {
        MultiplexLoggerStream.add(stream: ConsoleLoggerStream())
        if SdkEnvironment.isDebugEnabled {
            MultiplexLoggerStream.add(stream: RemoteLoggerStream(tenantId: storage.siteID ?? -1))
        } else {
            Logger.warn(
                "To enable debug logging set the application argument: \(SdkEnvironment.Constants.Key.debugEnabled)"
            )
        }
    }

}
