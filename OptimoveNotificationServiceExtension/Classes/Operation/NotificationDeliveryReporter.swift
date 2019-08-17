//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

final class NotificationDeliveryReporter: AsyncOperation {

    private let repository: ConfigurationRepository
    private let bundleIdentifier: String
    private let storage: OptimoveStorage
    private let notificationPayload: NotificationPayload

    init(repository: ConfigurationRepository,
         bundleIdentifier: String,
         storage: OptimoveStorage,
         notificationPayload: NotificationPayload) {
        self.repository = repository
        self.bundleIdentifier = bundleIdentifier
        self.storage = storage
        self.notificationPayload = notificationPayload
    }

    override func main() {
        state = .executing
        do {
            let configuration = try repository.getConfiguration()
            switch notificationPayload.campaign {
            case let campaign as ScheduledNotificationCampaign:
                try reportScheduledNotificationDelivered(campaign: campaign, configuration: configuration)
            case let campaign as TriggeredNotificationCampaign:
                try reportTriggeredNotificationDelivered(campaign: campaign, configuration: configuration)
            default:
                os_log("Unrecognized campaign type.", log: OSLog.reporter, type: .error)
                state = .finished
            }
        } catch {
            state = .finished
        }
    }
}

private extension NotificationDeliveryReporter {

    func reportTriggeredNotificationDelivered(
        campaign: TriggeredNotificationCampaign,
        configuration: Configuration) throws {
        let event = TriggeredNotificationDelivered(
            bundleId: self.bundleIdentifier,
            campaign: campaign
        )
        let eventConfig = try unwrap(configuration.events[event.name])
        try prepareAndSendEvent(event, eventConfig, configuration.optitrack)
    }

    func reportScheduledNotificationDelivered(
        campaign: ScheduledNotificationCampaign,
        configuration: Configuration) throws {
        let event = ScheduledNotificationDelivered(
            bundleId: self.bundleIdentifier,
            campaign: campaign
        )
        let eventConfig = try unwrap(configuration.events[event.name])
        try prepareAndSendEvent(event, eventConfig, configuration.optitrack)
    }

    func prepareAndSendEvent(_ event: OptimoveEvent,
                             _ eventConfig: EventsConfig,
                             _ optitrack: OptitrackConfig) throws {
        let queryItems = try buildQueryItems(event, eventConfig, optitrack)
        var reportEventUrl = URLComponents(url: optitrack.optitrackEndpoint, resolvingAgainstBaseURL: false)!
        reportEventUrl.queryItems = queryItems.filter { $0.value != nil }
        let reportEventRequest = URLRequest(
            url: reportEventUrl.url!,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 5
        )
        os_log("Sending a notification delivered event.", log: OSLog.reporter, type: .debug)
        URLSession.shared.dataTask(
            with: reportEventRequest,
            completionHandler: { [unowned self] (data, response, error) in
                if let error = error {
                    os_log("Error: %{PRIVATE}@", log: OSLog.reporter, type: .error, error.localizedDescription)
                } else {
                    os_log("Sent the notification delivered event.", log: OSLog.reporter, type: .debug)
                }
                self.state = .finished
            }
        ).resume()
    }

    func buildQueryItems(
        _ notificationEvent: OptimoveEvent,
        _ eventConfig: EventsConfig,
        _ optitrack: OptitrackConfig
        ) throws -> [URLQueryItem] {
        let date = Date()
        let currentUserAgent = try storage.getUserAgent()
        let userId = try storage.getCustomerID()
        let visitorId = try storage.getVisitorID()
        let initialVisitorId = try storage.getInitialVisitorId()

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idsite", value: String(describing: optitrack.tenantID)),
            URLQueryItem(name: "rec", value: "1"),
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "_id", value: visitorId),
            URLQueryItem(name: "uid", value: userId),
            URLQueryItem(name: "lang", value: Locale.httpAcceptLanguage),
            URLQueryItem(name: "ua", value: currentUserAgent),
            URLQueryItem(name: "h", value: DateFormatter.hourDateFormatter.string(from: date)),
            URLQueryItem(name: "m", value: DateFormatter.minuteDateFormatter.string(from: date)),
            URLQueryItem(name: "s", value: DateFormatter.secondsDateFormatter.string(from: date)),
            URLQueryItem(
                name: "res",
                value: String(format: "%1.0fx%1.0f",
                    try storage.getDeviceResolutionWidth(),
                    try storage.getDeviceResolutionHeight()
                )
            ),
            URLQueryItem(name: "e_c", value: optitrack.eventCategoryName),
            URLQueryItem(name: "e_a", value: "notification_delivered"),
            URLQueryItem(
                name: "dimension\(optitrack.customDimensionIDS.eventIDCustomDimensionID)",
                value: eventConfig.id.description
            ),
            URLQueryItem(
                name: "dimension\(optitrack.customDimensionIDS.eventNameCustomDimensionID)",
                value: notificationEvent.name
            )
        ]
        for (paramKey, paramConfig) in eventConfig.parameters {
            guard let paramValue = notificationEvent.parameters[paramKey] else { continue }
            queryItems.append(
                URLQueryItem(name: "dimension\(paramConfig.optiTrackDimensionId)", value: "\(paramValue)")
            )
        }
        return queryItems + queryItemsWithPluginFlags(from: initialVisitorId)
    }

    func queryItemsWithPluginFlags(from visitorId: String) -> [URLQueryItem] {
        let pluginFlags = ["fla", "java", "dir", "qt", "realp", "pdf", "wma", "gears"]
        let pluginValues = visitorId.splitedBy(length: 2).map { Int($0, radix: 16)!/2 }.map { $0.description }
        return pluginFlags.enumerated().map({ (arg) -> URLQueryItem in
            let pluginFlag = pluginFlags[arg.offset]
            let pluginValue = pluginValues[arg.offset]
            return URLQueryItem(name: pluginFlag, value: pluginValue)
        })
    }

}

extension OSLog {
    static let reporter = OSLog(subsystem: subsystem, category: "reporter")
}
