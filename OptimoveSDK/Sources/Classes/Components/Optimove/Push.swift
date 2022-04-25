//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import OptimoveCore
import UIKit

final class Push {

    private let registrar: Registrable
    private var storage: OptimoveStorage

    init(registrar: Registrable,
         storage: OptimoveStorage,
         application: UIApplication) {
        self.storage = storage
        self.registrar = registrar

        DispatchQueue.main.async {
            // Register for remote notifications right away.
            // This does not prompt for permissions to show notifications, but starts the device token registration.
            application.registerForRemoteNotifications()
        }

        Logger.debug("OptiPush initialized.")
        registrar.retryFailedOperationsIfExist()
    }

}

extension Push: CommonComponent {

    func serve(_ operation: CommonOperation) throws {
        switch operation {
        case let .deviceToken(token: token):
            storage.apnsToken = token
            registrar.handle(.setInstallation)
        case .setInstallation, .optIn, .optOut:
            guard storage.apnsToken != nil else { return }
            registrar.handle(.setInstallation)
        case let .togglePushCampaigns(areDisabled: areDisabled):
            storage.arePushCampaignsDisabled = areDisabled
            guard storage.apnsToken != nil else { return }
            registrar.handle(.setInstallation)
        case let .setPushNotificaitonChannels(channels: channels):
            storage.pushNotificationChannels = channels?.map { $0.lowercased() }
            registrar.handle(.setInstallation)
        default:
            break
        }
    }
}
