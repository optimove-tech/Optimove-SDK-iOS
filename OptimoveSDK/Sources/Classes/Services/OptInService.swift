//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class OptInService {

    private let synchronizer: Synchronizer
    private var storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory

    init(synchronizer: Synchronizer,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
        self.storage = storage
    }

    /// Handle changing of UserNotificaiont authorization status.
    func didPushAuthorization(isGranted granted: Bool) throws {
        requestTokenIfNeeded(pushAuthorizationGranted: granted)
        guard isOptStateChanged(with: granted) else { return }
        granted ? try executeOptIn() : try executeOptOut()
    }

}

private extension OptInService {

    /// Check if an OptIn/OptOut state was changed, or do nothing.
    func isOptStateChanged(with newState: Bool) -> Bool {
        return newState != storage.optFlag
    }

    func executeOptIn() throws {
        Logger.warn("OptiPush: User AUTHORIZED notifications.")
        storage.optFlag = true
        try coreEventFactory.createEvent(.optipushOptIn) { event in
            self.synchronizer.handle(.report(event: event))
        }
        synchronizer.handle(.optIn)
    }

    func executeOptOut() throws {
        Logger.warn("OptiPush: User UNAUTHORIZED notifications.")
        storage.optFlag = false
        try coreEventFactory.createEvent(.optipushOptOut) { event in
            self.synchronizer.handle(.report(event: event))
        }
        synchronizer.handle(.optOut)
    }

    func requestTokenIfNeeded(pushAuthorizationGranted: Bool) {
        guard pushAuthorizationGranted, storage.apnsToken == nil else { return }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

}
