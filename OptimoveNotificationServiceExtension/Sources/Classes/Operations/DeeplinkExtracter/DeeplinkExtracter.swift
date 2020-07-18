//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import os.log
import OptimoveCore

internal final class DeeplinkExtracter: AsyncOperation {

    struct Constants {
        static let dynamicLinksKey = "dynamic_link"
    }

    private let bundleIdentifier: String
    private let notificationPayload: NotificationPayload
    private let completionHandler: (String?) -> Void

    init(bundleIdentifier: String,
         notificationPayload: NotificationPayload,
         completionHandler: @escaping (String?) -> Void) {
        self.bundleIdentifier = bundleIdentifier
        self.notificationPayload = notificationPayload
        self.completionHandler = completionHandler
    }

    override func main() {
        state = .executing

        let appKey = bundleIdentifier
        guard let url = notificationPayload.dynamicLinks?.ios?[appKey] else {
            os_log("Found no deeplink", log: OSLog.extracter, type: .error)
            state = .finished
            return
        }
        let parser = DynamicLinkParser(
            parsingCallback: parserHandler
        )
        parser.parse(url)
    }

}

private extension DeeplinkExtracter {

    func parserHandler(result: Result<URL, Error>) {
        if (state == .cancelled) {
            return
        }
        switch result {
        case let .success(url):
            var urlString = replaceSpecialSymbols(in: url)
            let urlQueryAllowedSet = CharacterSet.urlQueryAllowed
            let alphanumericsSet = CharacterSet.alphanumerics
            if let value = notificationPayload.deepLinkPersonalization?.values {
                for (key, value) in value {
                    guard let percentKey = key.addingPercentEncoding(withAllowedCharacters: urlQueryAllowedSet) else {
                        continue
                    }
                    guard let percentValue = value.addingPercentEncoding(withAllowedCharacters: alphanumericsSet) else {
                        // any non-string values must be replaced with empty string
                        urlString = urlString.replacingOccurrences(of: percentKey, with: "")
                        continue
                    }
                    urlString = urlString.replacingOccurrences(of: percentKey, with: percentValue)
                }
            }
            os_log("Dynamic links were updated.", log: OSLog.extracter, type: .debug)
            completionHandler(urlString)

        case let .failure(error):
            os_log("Error: %{PUBLIC}@", log: OSLog.extracter, type: .error, error.localizedDescription)
        }
        state = .finished
    }

    func replaceSpecialSymbols(in url: URL) -> String {
        let urlString = url.absoluteString
        if let query = url.query {
            let replacingQuery = query.replacingOccurrences(of: "+", with: "%20")
            return urlString.replacingOccurrences(of: query, with: replacingQuery)
        }
        return urlString
    }

}

extension OSLog {
    static let extracter = OSLog(subsystem: subsystem, category: "extracter")
}
