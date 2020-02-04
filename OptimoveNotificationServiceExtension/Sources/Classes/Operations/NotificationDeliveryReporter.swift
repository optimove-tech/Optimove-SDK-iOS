//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

internal final class NotificationDeliveryReporter: AsyncOperation {

    private let bundleIdentifier: String
    private let notificationPayload: NotificationPayload
    private let optitrack: OptitrackNSE

    init(bundleIdentifier: String,
         notificationPayload: NotificationPayload,
         optitrack: OptitrackNSE) {
        self.bundleIdentifier = bundleIdentifier
        self.notificationPayload = notificationPayload
        self.optitrack = optitrack
    }

    override func main() {
        state = .executing
        do {
            let timestamp = Date().timeIntervalSince1970
            switch notificationPayload.campaign {
            case let campaign as ScheduledNotificationCampaign:
                try report(
                    ScheduledNotificationDelivered(
                        bundleId: bundleIdentifier,
                        campaign: campaign,
                        timestamp: timestamp
                    )
                )
            case let campaign as TriggeredNotificationCampaign:
                try report(
                    TriggeredNotificationRecieved(
                        bundleId: bundleIdentifier,
                        campaign: campaign,
                        timestamp: timestamp
                    )
                )
            default:
                os_log("Unrecognized campaign type.", log: OSLog.reporter, type: .error)
                state = .finished
            }
        } catch {
            os_log("Error: %{public}@", log: OSLog.reporter, type: .error, error.localizedDescription)
            state = .finished
        }
    }

    private func report(_ event: OptimoveEvent) throws {
try optitrack.report(
            event: event,
            completion: { [unowned self] in
                self.state = .finished
            }
        )
    }
}

extension OSLog {
    static let reporter = OSLog(subsystem: subsystem, category: "reporter")
}
