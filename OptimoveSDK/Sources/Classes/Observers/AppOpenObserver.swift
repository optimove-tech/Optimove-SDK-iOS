//  Copyright © 2019 Optimove. All rights reserved.
import Foundation
import OptimoveCore
import UIKit.UIApplication

final class AppOpenObserver {

    struct Constants {
        struct AppOpen {
            // The threshold used for throttling emits an AppOpen event.
            static let throttlingThreshold: TimeInterval = 1_800 // 30 minutes.
        }
    }

    private let synchronizer: Pipeline
    private var statisticService: StatisticService
    private let dateTimeProvider: DateTimeProvider
    private let coreEventFactory: CoreEventFactory

    init(synchronizer: Pipeline,
         statisticService: StatisticService,
         dateTimeProvider: DateTimeProvider,
         coreEventFactory: CoreEventFactory) {
        self.synchronizer = synchronizer
        self.statisticService = statisticService
        self.dateTimeProvider = dateTimeProvider
        self.coreEventFactory = coreEventFactory
    }

    func handleWillEnterForegroundNotification() throws {
        let threshold: TimeInterval = Constants.AppOpen.throttlingThreshold
        let now = dateTimeProvider.now.timeIntervalSince1970
        let appOpenTime = statisticService.applicationOpenTime
        if (now - appOpenTime) > threshold {
            let event = try coreEventFactory.createEvent(.appOpen)
            self.synchronizer.deliver(.report(events: [event]))
            self.statisticService.applicationOpenTime = self.dateTimeProvider.now.timeIntervalSince1970
        }
    }

}

extension AppOpenObserver: DeviceStateObservable {

    func observe() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] (_) in
            do {
                try self?.handleWillEnterForegroundNotification()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
