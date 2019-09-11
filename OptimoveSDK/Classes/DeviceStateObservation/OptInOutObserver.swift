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

    // MARK: Eventable logic

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
            if storage.isOptRequestSuccess {
                try handleNotificationAuthorized()
            }
        } else {
            try handlers.eventableHandler.handle(
                EventableOperationContext(
                    .report(event: try coreEventFactory.createEvent(.optipushOptOut))
                )
            )
            storage.isOptiTrackOptIn = false
            if storage.isOptRequestSuccess {
                try handleNotificationRejection()
            }
        }
    }

    private func isOptStateChanged(with newState: Bool) -> Bool {
        let isOptiTrackOptIn: Bool = storage.isOptiTrackOptIn
        return newState != isOptiTrackOptIn
    }

    // MARK: Pushable logic

    func handleNotificationAuthorized() throws {
        Logger.info("OptiPush: User authorized notifications.")
        guard let isOptIn = storage.isMbaasOptIn else {  //Opt in on first launch
            Logger.debug("OptiPush: User authorized notifications for the first time.")
            storage.isMbaasOptIn = true
            return
        }
        if !isOptIn {
            Logger.debug("OptiPush: SDK make opt IN request.")
            try handlers.pushableHandler.handle(.init(.optIn))
        }
    }

    func handleNotificationRejection() throws {
        Logger.warn("OptiPush: User UNauthorized notifications.")

        guard let isOptIn = storage.isMbaasOptIn else {
            //Opt out on first launch
            try handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            Logger.debug("OptiPush: SDK make opt OUT request.")
            try handlers.pushableHandler.handle(.init(.optOut))
            storage.isMbaasOptIn = false
        }
    }

    func handleNotificationRejectionAtFirstLaunch() throws {
        Logger.debug("OptiPush: User opt OUT at first launch.")
        guard storage.fcmToken != nil else {
            storage.isMbaasOptIn = false
            return
        }

        if storage.isRegistrationSuccess {
            storage.isMbaasOptIn = false
            try handlers.pushableHandler.handle(.init(.optOut))
        }
    }
}
