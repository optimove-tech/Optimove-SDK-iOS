//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ResignActiveObserver: DeviceStateObservable {

    private let handlers: HandlersPool

    init(handlers: HandlersPool) {
        self.handlers = handlers
    }

    func observe() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: self,
            queue: .main
        ) { [handlers] (_) in
            do {
                try handlers.eventableHandler.handle(EventableOperationContext(.dispatchNow))
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
