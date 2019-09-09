//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptInOutObserver: DeviceStateObservable {

    private let handlers: HandlersPool
    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    private let coreEventFactory: CoreEventFactory
    private var storage: OptimoveStorage

    init(handlers: HandlersPool,
         deviceStateMonitor: OptimoveDeviceStateMonitor,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage) {
        self.handlers = handlers
        self.deviceStateMonitor = deviceStateMonitor
        self.coreEventFactory = coreEventFactory
        self.storage = storage
    }

    func observe() {
        deviceStateMonitor.getStatus(for: .userNotification) { (granted) in
            do {
                try self.executeReportOptInOut(notificationsPermissionsGranted: granted)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    private func executeReportOptInOut(notificationsPermissionsGranted: Bool) throws {
        guard isOptStateChanged(with: notificationsPermissionsGranted) else {
            // An OptIn/OptOut state was not changed.
            return
        }
        if notificationsPermissionsGranted {
            try handlers.eventableHandler.handle(
                EventableOperationContext(
                    .report(event: try coreEventFactory.createEvent(.optipushOptIn))
                )
            )
            storage.isOptiTrackOptIn = true
        } else {
            try handlers.eventableHandler.handle(
                EventableOperationContext(
                    .report(event: try coreEventFactory.createEvent(.optipushOptOut))
                )
            )
            storage.isOptiTrackOptIn = false
        }
    }

    private func isOptStateChanged(with newState: Bool) -> Bool {
        let isOptiTrackOptIn: Bool = storage.isOptiTrackOptIn
        return newState != isOptiTrackOptIn
    }
}
