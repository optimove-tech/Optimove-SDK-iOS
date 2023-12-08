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
        MultiplexLoggerStream.add(stream: RemoteLoggerStream(tenantId: storage.tenantID ?? -1))
    }
}
