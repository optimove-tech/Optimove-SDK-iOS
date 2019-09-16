//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

/// Optitrack for Notification Service Extension protocol.
protocol OptitrackNSE {
    func report(event: OptimoveEvent, completion: @escaping () -> Void) throws
}

// TODO: Replace with the normal Optitrack component.
final class OptitrackNSEImpl {

    private let storage: OptimoveStorage
    private let repository: ConfigurationRepository

    init(storage: OptimoveStorage,
         repository: ConfigurationRepository) {
        self.storage = storage
        self.repository = repository
    }

}

extension OptitrackNSEImpl: OptitrackNSE {

    func report(event: OptimoveEvent, completion: @escaping () -> Void) throws {
        let reportEventRequest = try buildRequest(event: event)
        os_log("Sending a notification delivered event.", log: OSLog.optitrack, type: .debug)
        let task = URLSession.shared.dataTask(with: reportEventRequest, completionHandler: { (data, response, error) in
            if let error = error {
                os_log("Error: %{PRIVATE}@", log: OSLog.optitrack, type: .error, error.localizedDescription)
            } else {
                os_log("Sent the notification delivered event.", log: OSLog.optitrack, type: .debug)
            }
            completion()
        })
        task.resume()
    }
}

private extension OptitrackNSEImpl {

    func buildRequest(event: OptimoveEvent) throws -> URLRequest {
        let configuration = try repository.getConfiguration()
        let queryItems = try buildQueryItems(
            event: event,
            config: try unwrap(configuration.events[event.name]),
            optitrack: configuration.optitrack
        )
        let baseURL: URL = {
            let piwikPath = "piwik.php"
            if !configuration.optitrack.optitrackEndpoint.absoluteString.contains(piwikPath) {
                return configuration.optitrack.optitrackEndpoint.appendingPathComponent(piwikPath)
            }
            return configuration.optitrack.optitrackEndpoint
        }()
        var reportEventUrl = try unwrap(
            URLComponents(
                url: baseURL,
                resolvingAgainstBaseURL: false
            )
        )
        reportEventUrl.queryItems = queryItems.filter { $0.value != nil }
        return URLRequest(
            url: try unwrap(reportEventUrl.url),
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 5
        )
    }

    func buildQueryItems(
        event: OptimoveEvent,
        config: EventsConfig,
        optitrack: OptitrackConfig
    ) throws -> [URLQueryItem] {

        let date = Date()
        let currentUserAgent = try storage.getUserAgent()
        let userId = storage.customerID
        let visitorID = try storage.getVisitorID()
        let initialVisitorId = try storage.getInitialVisitorId()

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idsite", value: String(describing: optitrack.tenantID)),
            URLQueryItem(name: "rec", value: "1"),

            URLQueryItem(name: "_id", value: visitorID),
            URLQueryItem(name: "cid", value: visitorID),
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
            URLQueryItem(name: "e_a", value: event.name),
            URLQueryItem(
                name: "dimension\(optitrack.customDimensionIDS.eventIDCustomDimensionID)",
                value: config.id.description
            ),
            URLQueryItem(
                name: "dimension\(optitrack.customDimensionIDS.eventNameCustomDimensionID)",
                value: event.name
            )
        ]
        for (paramKey, paramConfig) in config.parameters {
            guard let paramValue = event.parameters[paramKey] else { continue }
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
    static let optitrack = OSLog(subsystem: subsystem, category: "OptitrackNSE")
}
