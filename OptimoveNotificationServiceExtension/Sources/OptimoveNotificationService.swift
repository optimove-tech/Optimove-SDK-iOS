//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit
import UserNotifications

public enum OptimoveNotificationService {
    enum Error: String, LocalizedError {
        case noBestAttemptContent
        case userInfoNotValid
    }

    public static func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        Task {
            do {
                let bestAttemptContent = try await didReceive(request)
                contentHandler(bestAttemptContent)
            } catch {
                assertionFailure(error.localizedDescription)
                contentHandler(request.content)
            }
        }
    }

    static func didReceive(_ request: UNNotificationRequest) async throws -> UNNotificationContent {
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            throw Error.noBestAttemptContent
        }
        let userInfo = request.content.userInfo
        guard JSONSerialization.isValidJSONObject(userInfo) else {
            throw Error.userInfoNotValid
        }
        let data = try JSONSerialization.data(withJSONObject: userInfo)
        let notification = try JSONDecoder().decode(PushNotification.self, from: data)
        if bestAttemptContent.categoryIdentifier.isEmpty {
            bestAttemptContent.categoryIdentifier = await registerCategory(notification: notification)
        }
        if let storage = try? UserDefaults.optimoveAppGroup() {
            let mediaHelper = MediaHelper(storage: storage)
            if let attachment = try await maybeGetAttachment(
                notification: notification,
                mediaHelper: mediaHelper
            ) {
                bestAttemptContent.attachments = [attachment]
            }
            let optimobileHelper = OptimobileHelper(storage: storage)
            if let badge = optimobileHelper.getBadge(notification: notification) {
                storage.set(value: badge, key: .badgeCount)
                bestAttemptContent.badge = NSNumber(integerLiteral: badge)
            }
            let pendingNoticationHelper = PendingNotificationHelper(storage: storage)
            pendingNoticationHelper.add(
                notification: PendingNotification(
                    id: notification.message.id,
                    identifier: request.identifier
                )
            )
        }

        return bestAttemptContent
    }

    static func buildActions(notification: PushNotification) -> [UNNotificationAction] {
        return notification.buttons?.map { button in
            if #available(iOS 15.0, *) {
                return UNNotificationAction(
                    identifier: button.id,
                    title: button.text,
                    options: .foreground,
                    icon: buildIcon(button: button)
                )
            } else {
                return UNNotificationAction(
                    identifier: button.id,
                    title: button.text,
                    options: .foreground
                )
            }
        } ?? []
    }

    @available(iOS 15.0, *)
    static func buildIcon(button: PushNotification.Button) -> UNNotificationActionIcon? {
        guard let icon = button.icon else { return nil }
        switch icon.type {
        case .custom:
            return UNNotificationActionIcon(templateImageName: icon.id)
        case .system:
            return UNNotificationActionIcon(systemImageName: icon.id)
        }
    }

    static func registerCategory(notification: PushNotification) async -> String {
        let categoryIdentifier = CategoryManager.getCategoryId(messageId: notification.message.id)
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: buildActions(notification: notification),
            intentIdentifiers: [],
            options: .customDismissAction
        )
        await CategoryManager.registerCategory(category)

        return categoryIdentifier
    }

    static func maybeGetAttachment(notification: PushNotification, mediaHelper: MediaHelper) async throws -> UNNotificationAttachment? {
        guard let picturePath = notification.attachment?.pictureUrl else { return nil }

        let url = try await mediaHelper.getCompletePictureUrl(
            pictureUrlString: picturePath,
            width: UInt(floor(UIScreen.main.bounds.size.width))
        )

        return try await downloadAttachment(url: url)
    }

    static func downloadAttachment(url: URL) async throws -> UNNotificationAttachment {
        let (data, response) = try await URLSession.shared.data(from: url)
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension((response.url ?? url).pathExtension)
        try data.write(to: tempURL)

        return try UNNotificationAttachment(
            identifier: "",
            url: tempURL
        )
    }
}
