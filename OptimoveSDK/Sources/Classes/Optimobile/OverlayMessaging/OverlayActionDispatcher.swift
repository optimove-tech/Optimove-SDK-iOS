//  Copyright © 2025 Optimove. All rights reserved.

import Foundation
import UIKit

final class OverlayActionDispatcher {

    private let handlerForType: (OverlayActionType) -> OverlayActionHandler?
    private let openURL: (URL) -> Void
    private let logError: (String) -> Void

    init(
        handlerForType: @escaping (OverlayActionType) -> OverlayActionHandler?,
        openURL: @escaping (URL) -> Void = OverlayActionDispatcher.defaultOpenURL,
        logError: @escaping (String) -> Void = { Logger.error($0) }
    ) {
        self.handlerForType = handlerForType
        self.openURL = openURL
        self.logError = logError
    }

    func performButtonLink(
        message: OverlayMessagingMessage,
        data: NSDictionary
    ) {
        guard let urlString = data["url"] as? String else { return }
        let payload = Self.payload(from: data)

        performAction(
            type: .buttonLink,
            message: message,
            data: payload
        ) { [openURL] in
            guard let url = URL(string: urlString) else { return }
            openURL(url)
        }
    }

    func performAction(
        type: OverlayActionType,
        message: OverlayMessagingMessage,
        data: [String: Any],
        defaultBehavior: @escaping () -> Void
    ) {
        runOnMain {
            guard let handler = self.handlerForType(type) else {
                defaultBehavior()
                return
            }

            do {
                try handler(message, data)
            } catch {
                self.logError("Error in overlay action handler: \(error.localizedDescription)")
            }
        }
    }

    private static func payload(from data: NSDictionary) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in data {
            if let key = key as? String {
                result[key] = value
            }
        }
        return result
    }

    private func runOnMain(_ work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    private static func defaultOpenURL(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}
