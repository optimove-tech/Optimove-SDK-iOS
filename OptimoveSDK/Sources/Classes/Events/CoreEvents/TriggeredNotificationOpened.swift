//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TriggeredNotificationOpened: OptimoveCoreEvent {

    struct Constants {
        static let name = "triggered_notification_opened"
        struct Key {
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
            static let templateID = OptimoveKeys.Notification.templateId.rawValue
            static let actionSerial = OptimoveKeys.Notification.actionSerial.rawValue
            static let actionID = OptimoveKeys.Notification.actionId.rawValue
        }
    }

    let name: String = Constants.name
    let parameters: [String: Any]

    init(bundleIdentifier: String, campaign: TriggeredNotificationCampaign, date: Date = Date()) {
        parameters = [
            Constants.Key.timestamp: Int(date.timeIntervalSince1970),
            Constants.Key.appNS: bundleIdentifier,
            Constants.Key.templateID: campaign.templateID,
            Constants.Key.actionSerial: campaign.actionSerial,
            Constants.Key.actionID: campaign.actionID
        ]
    }

}
