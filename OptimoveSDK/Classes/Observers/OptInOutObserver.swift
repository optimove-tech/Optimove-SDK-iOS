//  Copyright © 2019 Optimove. All rights reserved.

import UIKit
import OptimoveCore

final class OptInOutObserver {

    private let optInService: OptInService

    init(optInService: OptInService) {
        self.optInService = optInService
    }

}

extension OptInOutObserver: DeviceStateObservable {

    func observe() {
        checkSettings()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] (_) in
            self?.checkSettings()
        }
    }

}

private extension OptInOutObserver {

    func checkSettings() {
        let onGetNotificationSettings: (UNNotificationSettings) -> Void = { [optInService] (settings) in
            tryCatch {
                if #available(iOS 12.0, *) {
                    let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                    try optInService.didPushAuthorization(isGranted: isAuthorized)
                } else {
                    let isAuthorized = settings.authorizationStatus == .authorized
                    try optInService.didPushAuthorization(isGranted: isAuthorized)
                }
            }
        }
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: onGetNotificationSettings)
    }

}
