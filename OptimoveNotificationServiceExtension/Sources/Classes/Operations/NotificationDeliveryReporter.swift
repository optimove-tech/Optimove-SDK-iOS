//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

internal final class NotificationDeliveryReporter: AsyncOperation {

    private let bundleIdentifier: String
    private let notificationPayload: NotificationPayload
    private let networking: OptistreamNetworking

    init(bundleIdentifier: String,
         notificationPayload: NotificationPayload,
         networking: OptistreamNetworking) {
        self.bundleIdentifier = bundleIdentifier
        self.notificationPayload = notificationPayload
        self.networking = networking
    }

    override func main() {
        guard !self.isCancelled else { return }
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
            let optistreamEvent = OptistreamEvent(
                tenant: notificationPayload.eventVariables.tenant,
                category: event.category,
                event: event.name,
                origin: "sdk",
                customer: notificationPayload.eventVariables.customer,
                visitor: notificationPayload.eventVariables.visitor,
                timestamp: Formatter.iso8601withFractionalSeconds.string(from: event.timestamp),
                context: try JSON(event.context),
                metadata: OptistreamEvent.Metadata(
                    channel: OptistreamEvent.Metadata.Channel(
                        airship: nil
                    ),
                    realtime: event.isRealtime,
                    firstVisitorDate: notificationPayload.eventVariables.firstRunTimestamp,
                    eventId: event.eventId.uuidString,
                    validations: []
                )
            )
            try report(optistreamEvent)
        } catch {
            os_log("Error: %{public}@", log: OSLog.reporter, type: .error, error.localizedDescription)
            state = .finished
        }
    }

    private func report(_ event: OptistreamEvent) throws {
        networking.send(events: [event]) { [weak self] (result) in
            guard !(self?.isCancelled ?? true) else { return }
            switch result {
            case .success:
                    os_log("Delivery reported", log: OSLog.reporter, type: .info)
            case .failure(let error):
                os_log("Error: %{public}@", log: OSLog.reporter, type: .error, error.localizedDescription)
            }
            self?.state = .finished
        }
    }
}

extension OSLog {
    static let reporter = OSLog(subsystem: subsystem, category: "reporter")
}
