//  Copyright © 2019 Optimove. All rights reserved.

import UIKit
import OptimoveCore

final class OptInOutObserver {

    private let optInService: OptInService
    private let notificationPermissionFetcher: NotificationPermissionFetcher

    init(optInService: OptInService,
         notificationPermissionFetcher: NotificationPermissionFetcher) {
        self.optInService = optInService
        self.notificationPermissionFetcher = notificationPermissionFetcher
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
        notificationPermissionFetcher.fetch { [optInService] (granted) in
            tryCatch {
                try optInService.didPushAuthorization(isGranted: granted)
            }
        }
    }

}
