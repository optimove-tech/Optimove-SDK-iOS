//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class OptInService {

    private let synchronizer: Synchronizer
    private var storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory
    private var subscribers: [OptInOutSubscriber]

    init(synchronizer: Synchronizer,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage,
         subscribers: [OptInOutSubscriber]) {
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
        self.storage = storage
        self.subscribers = subscribers
    }

    func didPushAuthorization(isGranted: Bool) throws {
        let status: OptStatus = isGranted ? .optIn : .optOut
        try didPushAuthorization(status: status)
    }

    /// Handle changing of UserNotificaiont authorization status.
    func didPushAuthorization(status: OptStatus) throws {
        requestTokenIfNeeded(status: status)
        guard isOptStateChanged(status: status) else { return }
        subscribers.forEach({ $0.statusChanged(status: status) })
        switch status {
        case .optIn:
            try executeOptIn()
        case .optOut:
            try executeOptOut()
        }
    }

}

private extension OptInService {

    /// Check if an OptIn/OptOut state was changed, or do nothing.
    func isOptStateChanged(status: OptStatus) -> Bool {
        return (status == .optIn) != storage.optFlag
    }

    func executeOptIn() throws {
        Logger.warn("OptiPush: User AUTHORIZED notifications.")
        storage.optFlag = true
        let event = try coreEventFactory.createEvent(.optipushOptIn)
        self.synchronizer.handle(.report(events: [event]))
        synchronizer.handle(.optIn)
    }

    func executeOptOut() throws {
        Logger.warn("OptiPush: User UNAUTHORIZED notifications.")
        storage.optFlag = false
        let event = try coreEventFactory.createEvent(.optipushOptOut)
        self.synchronizer.handle(.report(events: [event]))
        synchronizer.handle(.optOut)
    }

    func requestTokenIfNeeded(status: OptStatus) {
        guard status == .optIn, storage.apnsToken == nil else { return }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

}

protocol OptInOutSubscriber {
    func statusChanged(status: OptStatus)
}
