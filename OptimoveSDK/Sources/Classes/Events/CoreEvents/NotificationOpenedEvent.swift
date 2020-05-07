//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NotificationOpenedEvent: Event {

    struct Constants {
        static let category = "optipush"
        struct Key {
            static let identityToken = "identity_token"
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
        }
    }

    init(
        bundleIdentifier: String,
        notificationType: NotificationCampaignType,
        identityToken: String,
        timestamp: Date = Date()
    ) {
        super.init(
            name: notificationType.eventName,
            category: Constants.category,
            context: [
                Constants.Key.timestamp: timestamp.timeIntervalSince1970.seconds,
                Constants.Key.identityToken: identityToken,
                Constants.Key.appNS: bundleIdentifier
            ]
        )
    }

}

extension NotificationCampaignType {

    var eventName: String {
        switch self {
        case .scheduled:
            return "notification_opened"
        case .triggered:
            return "triggered_notification_opened"
        }
    }

}
