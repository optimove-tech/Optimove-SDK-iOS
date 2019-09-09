//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class EnterForegroundObserver {

    struct Constants {
        struct AppOpen {
            // The threshold used for throttling emits an AppOpen event.
            static let throttlingThreshold: TimeInterval = 1_800 // 30 minutes.
        }
    }

    private let handlers: HandlersPool
    private var statisticService: StatisticService
    private let dateTimeProvider: DateTimeProvider
    private let coreEventFactory: CoreEventFactory

    init(handlers: HandlersPool,
         statisticService: StatisticService,
         dateTimeProvider: DateTimeProvider,
         coreEventFactory: CoreEventFactory) {
        self.handlers = handlers
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
            try handlers.eventableHandler.handle(EventableOperationContext(.report(event: event)))
            statisticService.applicationOpenTime = dateTimeProvider.now.timeIntervalSince1970
        }
    }

}

extension EnterForegroundObserver: DeviceStateObservable {

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
