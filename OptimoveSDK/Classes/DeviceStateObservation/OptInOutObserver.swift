//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptInOutObserver: DeviceStateObservable {

    private let synchronizer: Synchronizer
    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    private let coreEventFactory: CoreEventFactory
    private var storage: OptimoveStorage

    init(synchronizer: Synchronizer,
         deviceStateMonitor: OptimoveDeviceStateMonitor,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        self.deviceStateMonitor = deviceStateMonitor
        self.coreEventFactory = coreEventFactory
        self.storage = storage
    }

    func observe() {
        deviceStateMonitor.getStatus(for: .userNotification) { (granted) in
            tryCatch {
                try self.executeReportOptInOut(notificationsPermissionsGranted: granted)
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
            synchronizer.handle(.report(event: try coreEventFactory.createEvent(.optipushOptIn)))
            storage.isOptiTrackOptIn = true
            if storage.isOptRequestSuccess {
                handleNotificationAuthorized()
            }
        } else {
            synchronizer.handle(.report(event: try coreEventFactory.createEvent(.optipushOptOut)))
            storage.isOptiTrackOptIn = false
            if storage.isOptRequestSuccess {
                handleNotificationRejection()
            }
        }
    }

    private func isOptStateChanged(with newState: Bool) -> Bool {
        let isOptiTrackOptIn: Bool = storage.isOptiTrackOptIn
        return newState != isOptiTrackOptIn
    }

    // MARK: Pushable logic

    func handleNotificationAuthorized() {
        Logger.info("OptiPush: User authorized notifications.")
        guard let isOptIn = storage.isMbaasOptIn else {  //Opt in on first launch
            Logger.debug("OptiPush: User authorized notifications for the first time.")
            storage.isMbaasOptIn = true
            return
        }
        if !isOptIn {
            Logger.debug("OptiPush: SDK make opt IN request.")
            synchronizer.handle(.optIn)
        }
    }

    func handleNotificationRejection() {
        Logger.warn("OptiPush: User UNauthorized notifications.")

        guard let isOptIn = storage.isMbaasOptIn else {
            //Opt out on first launch
            handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            Logger.debug("OptiPush: SDK make opt OUT request.")
            synchronizer.handle(.optOut)
            storage.isMbaasOptIn = false
        }
    }

    func handleNotificationRejectionAtFirstLaunch() {
        Logger.debug("OptiPush: User opt OUT at first launch.")
        guard storage.fcmToken != nil else {
            storage.isMbaasOptIn = false
            return
        }

        if storage.isRegistrationSuccess {
            storage.isMbaasOptIn = false
            synchronizer.handle(.optOut)
        }
    }
}
