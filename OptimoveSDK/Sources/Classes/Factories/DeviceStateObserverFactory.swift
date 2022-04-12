//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

final class DeviceStateObserverFactory {

    private let statisticService: StatisticService
    private let synchronizer: Pipeline
    private let dateTimeProvider: DateTimeProvider
    private let coreEventFactory: CoreEventFactory
    private let storage: OptimoveStorage

    init(statisticService: StatisticService,
         synchronizer: Pipeline,
         dateTimeProvider: DateTimeProvider,
         coreEventFactory: CoreEventFactory,
         storage: OptimoveStorage) {
        self.statisticService = statisticService
        self.synchronizer = synchronizer
        self.dateTimeProvider = dateTimeProvider
        self.coreEventFactory = coreEventFactory
        self.storage = storage
    }
    
    func build() -> DeviceStateObserver {
        return DeviceStateObserver(
            observers: [
                MigrationObserver(
                    migrationWorks: [
                        MigrationWork_2_10_0(synchronizer: synchronizer, storage: storage),
                        MigrationWork_3_0_0(storage: storage)
                    ]
                ),
                ResignActiveObserver(
                    subscriber: synchronizer
                )
            ]
        )
    }
    
}
