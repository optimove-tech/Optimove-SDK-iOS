//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

internal final class NotificationDeliveryReporter: AsyncOperation {

    private let bundleIdentifier: String
    private let notificationPayload: NotificationPayload
    private let networking: OptistreamNetworking
    private let builder: OptistreamEventBuilder

    init(bundleIdentifier: String,
         notificationPayload: NotificationPayload,
         networking: OptistreamNetworking,
         builder: OptistreamEventBuilder) {
        self.bundleIdentifier = bundleIdentifier
        self.notificationPayload = notificationPayload
        self.networking = networking
        self.builder = builder
    }

    override func main() {
        state = .executing
        guard let campaign = notificationPayload.campaign else {
            os_log("Unrecognized campaign type.", log: OSLog.reporter, type: .error)
            state = .finished
            return
        }
        do {
            let event = NotificationDeliveredEvent(
                bundleId: bundleIdentifier,
                notificationType: campaign.type,
                identityToken: campaign.identityToken
            )
            let optistreamEvent = try builder.build(event: event)
            try report(optistreamEvent)
        } catch {
            os_log("Error: %{public}@", log: OSLog.reporter, type: .error, error.localizedDescription)
            state = .finished
        }
    }

    private func report(_ event: OptistreamEvent) throws {
        networking.send(events: [event]) { [unowned self] (result) in
            switch result {
            case .success():
                    os_log("Delivery reported", log: OSLog.reporter, type: .info)
            case .failure(let error):
                os_log("Error: %{public}@", log: OSLog.reporter, type: .error, error.localizedDescription)
            }
            self.state = .finished
        }
    }
}

extension OSLog {
    static let reporter = OSLog(subsystem: subsystem, category: "reporter")
}
