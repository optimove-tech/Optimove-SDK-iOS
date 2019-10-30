//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit

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
        checkSettings()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] (_) in
            self?.checkSettings()
        }
    }

}

private extension OptInOutObserver {

    func checkSettings() {
        notificationPermissionFetcher.fetch { (permitted) in
            tryCatch {
                /// Check if an OptIn/OptOut state was changed, or do nothing.
                guard self.isOptStateChanged(with: permitted) else { return }
                permitted ? try self.executeOptIn() : try self.executeOptOut()
            }
        }
    }

    func isOptStateChanged(with newState: Bool) -> Bool {
        return newState != storage.optFlag
    }

    func executeOptIn() throws {
        Logger.warn("OptiPush: User AUTHORIZED notifications.")
        storage.optFlag = true
        synchronizer.handle(.report(event: try coreEventFactory.createEvent(.optipushOptIn)))
        synchronizer.handle(.optIn)
    }

    func executeOptOut() throws {
        Logger.warn("OptiPush: User UNAUTHORIZED notifications.")
        storage.optFlag = false
        synchronizer.handle(.report(event: try coreEventFactory.createEvent(.optipushOptOut)))
        synchronizer.handle(.optOut)
    }

}
