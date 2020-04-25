//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TriggeredNotificationOpened: Event {

    struct Constants {
        static let name = "triggered_notification_opened"
        static let category = "optipush"
        struct Key {
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
            static let templateID = OptimoveKeys.Notification.templateId.rawValue
            static let actionSerial = OptimoveKeys.Notification.actionSerial.rawValue
            static let actionID = OptimoveKeys.Notification.actionId.rawValue
        }
    }

    init(bundleIdentifier: String, campaign: TriggeredNotificationCampaign, date: Date = Date()) {
        super.init(
            name: Constants.name,
            category: Constants.category,
            context: [
                Constants.Key.timestamp: Int(date.timeIntervalSince1970),
                Constants.Key.appNS: bundleIdentifier,
                Constants.Key.templateID: campaign.templateID,
                Constants.Key.actionSerial: campaign.actionSerial,
                Constants.Key.actionID: campaign.actionID
            ]
        )
    }

}
