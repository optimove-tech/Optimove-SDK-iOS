// Copiright 2019 Optimove

import Foundation
import os.log

final class NotificationDeliveryReporter: AsyncOperation {
    
    private let repository: ConfigurationRepository
    private let bundleIdentifier: String
    private let sharedDefaults: UserDefaults
    private let notificationPayload: NotificationPayload
    
    init(repository: ConfigurationRepository,
         bundleIdentifier: String,
         sharedDefaults: UserDefaults,
         notificationPayload: NotificationPayload) {
        self.repository = repository
        self.bundleIdentifier = bundleIdentifier
        self.sharedDefaults = sharedDefaults
        self.notificationPayload = notificationPayload
    }
    
    override func main() {
        state = .executing
        
        let configuration: OptimoveConfigForExtension
        do {
            configuration = try repository.obtain()
        } catch {
            state = .finished
            return
        }
        
        let optitrackMetadata = configuration.optitrackMetaData
        let eventConfigs = configuration.events
        
        guard let campaignDetails = notificationPayload.campaignDetails,
            let eventConfig = eventConfigs["notification_delivered"] else {
            state = .finished
            return
        }
        let notificationEvent = NotificationDelivered(
            bundleId: self.bundleIdentifier,
            campaignDetails: campaignDetails,
            currentDeviceOS: "iOS \(ProcessInfo().operatingSystemVersionOnlyString)"
        )
        let queryItems = buildQueryItems(notificationEvent, eventConfig, optitrackMetadata)
        var reportEventUrl = URLComponents(string: optitrackMetadata.optitrackEndpoint)!
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
}

private extension NotificationDeliveryReporter {

    func buildQueryItems(
        _ notificationEvent: NotificationDelivered,
        _ eventConfig: OptimoveEventConfig,
        _ optitrackMetadata: OptitrackMetadata
        ) -> [URLQueryItem] {
        let date = Date()
        
        let currentUserAgent = sharedDefaults.string(forKey: "userAgent")!
        
        let userId = sharedDefaults.string(forKey: "customerID")
        let visitorId = sharedDefaults.string(forKey: "visitorID")
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idsite", value: String(describing: optitrackMetadata.siteId)),
            URLQueryItem(name: "rec", value: "1"),
            URLQueryItem(name: "api", value: "1"),
            // Visitor
            URLQueryItem(name: "_id", value: visitorId),
            URLQueryItem(name: "uid", value: userId),
            // Session
            URLQueryItem(name: "lang", value: Locale.httpAcceptLanguage),
            URLQueryItem(name: "ua", value: currentUserAgent),
            URLQueryItem(name: "h", value: DateFormatter.hourDateFormatter.string(from: date)),
            URLQueryItem(name: "m", value: DateFormatter.minuteDateFormatter.string(from: date)),
            URLQueryItem(name: "s", value: DateFormatter.secondsDateFormatter.string(from: date)),
            //screen resolution
            URLQueryItem(
                name: "res",
                value: String(
                    format: "%1.0fx%1.0f",
                    self.sharedDefaults.double(forKey: "deviceResolutionWidth"),
                    self.sharedDefaults.double(forKey: "deviceResolutionHeight")
                )
            ),
            URLQueryItem(name: "e_c", value: optitrackMetadata.eventCategoryName),
            URLQueryItem(name: "e_a", value: "notification_delivered"),
            URLQueryItem(
                name: "dimension\(optitrackMetadata.eventIdCustomDimensionId)",
                value: eventConfig.id.description
            ),
            URLQueryItem(
                name: "dimension\(optitrackMetadata.eventNameCustomDimensionId)",
                value: notificationEvent.name
            )
        ]
        for (paramKey, paramConfig) in eventConfig.parameters {
            guard let paramValue = notificationEvent.parameters[paramKey] else { continue }
            queryItems.append(
                URLQueryItem(name: "dimension\(paramConfig.optiTrackDimensionId)", value: "\(paramValue)")
            )
        }
        return queryItems + queryItemsWithPluginFlags(from: sharedDefaults.string(forKey: "initialVisitorId")!)
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
