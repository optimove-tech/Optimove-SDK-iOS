//
//  NotificationResponder.swift
//  DevelopSDK
//
//  Created by Elkana Orbach on 23/11/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import UserNotifications

class OptimoveNotificationHandler: NSObject,
    UNUserNotificationCenterDelegate
{
    override init()
    {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        LogManager.reportToConsole("Ask for user permission to present notifications")
        
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        Optimove.sharedInstance.handleUserNotificationResponse(response:response)
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert,.sound])
    }
}
