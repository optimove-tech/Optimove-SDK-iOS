//  Copyright © 2020 Optimove. All rights reserved.

final class DeviceStateObserverFactory {

    private let statisticService: StatisticService
    private let synchronizer: Synchronizer
    private let optInService: OptInService
    private let dateTimeProvider: DateTimeProvider
    private let coreEventFactory: CoreEventFactory

    init(statisticService: StatisticService,
         synchronizer: Synchronizer,
         optInService: OptInService,
         dateTimeProvider: DateTimeProvider,
         coreEventFactory: CoreEventFactory) {
        self.statisticService = statisticService
        self.synchronizer = synchronizer
        self.optInService = optInService
        self.dateTimeProvider = dateTimeProvider
        self.coreEventFactory = coreEventFactory
    }

    func build() -> DeviceStateObserver {
        return DeviceStateObserver(
            observers: [
                ResignActiveObserver(
                    subscriber: synchronizer
                ),
                OptInOutObserver(
                    optInService: optInService,
                    notificationPermissionFetcher: NotificationPermissionFetcherImpl()
                ),
                AppOpenObserver(
                    synchronizer: synchronizer,
                    statisticService: statisticService,
                    dateTimeProvider: dateTimeProvider,
                    coreEventFactory: coreEventFactory
                )
            ]
        )
    }

}
