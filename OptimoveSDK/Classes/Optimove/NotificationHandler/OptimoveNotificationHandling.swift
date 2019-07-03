//
//  OptimoveNotificationHandling.swift
//  OptimoveSDK

import Foundation
import UserNotifications

protocol OptimoveNotificationHandling {
    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    )

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping (() -> Void)
    )
}
