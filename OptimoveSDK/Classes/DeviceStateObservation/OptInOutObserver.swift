//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptInOutObserver {

    private let synchronizer: Synchronizer
    private let notificationPermissionFetcher: NotificationPermissionFetcher
    private let coreEventFactory: CoreEventFactory
    private var storage: OptimoveStorage

    init(synchronizer: Synchronizer,
         notificationPermissionFetcher: NotificationPermissionFetcher,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        self.notificationPermissionFetcher = notificationPermissionFetcher
        self.coreEventFactory = coreEventFactory
        self.storage = storage
    }

}

extension OptInOutObserver: DeviceStateObservable {

    func observe() {
        notificationPermissionFetcher.fetch { (permitted) in
            tryCatch {
                try self.executeReportOptInOut(notificationsPermissionsGranted: permitted)
            }
        }
    }

}

private extension OptInOutObserver {

    // MARK: Eventable logic

    func executeReportOptInOut(notificationsPermissionsGranted: Bool) throws {
        // Check if an OptIn/OptOut state was changed. If not do nothing.
        guard isOptStateChanged(with: notificationsPermissionsGranted) else { return }
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

    func isOptStateChanged(with newState: Bool) -> Bool {
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

        if let isSettingUserSuccess = storage.isSettingUserSuccess, isSettingUserSuccess == true {
            storage.isMbaasOptIn = false
            synchronizer.handle(.optOut)
        }
    }
}
