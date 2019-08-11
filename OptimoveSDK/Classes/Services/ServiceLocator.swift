// Copiright 2019 Optimove

import Foundation

final class ServiceLocator {

    // MARK: - Singletons

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _deviceStateMonitor: OptimoveDeviceStateMonitor = {
        return OptimoveDeviceStateMonitorImpl(
            fetcherFactory: DeviceRequirementFetcherFactoryImpl()
        )
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _warehouseProvider: EventsConfigWarehouseProvider = {
        return EventsConfigWarehouseProvider()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _realtimeMetaDataProvider: MetaDataProvider<RealtimeMetaData> = {
        return MetaDataProvider<RealtimeMetaData>()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _optitrackMetaData: MetaDataProvider<OptitrackMetaData> = {
        return MetaDataProvider<OptitrackMetaData>()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _optipushMetaData: MetaDataProvider<OptipushMetaData> = {
        return MetaDataProvider<OptipushMetaData>()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _notificationListener: OptimoveNotificationHandler = {
        return OptimoveNotificationHandler(
            storage: storage(),
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage(),
                dateTimeProvider: dateTimeProvider()
            ),
            optimove: Optimove.shared
        )
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _storage: OptimoveStorageFacade = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("The `CFBundleIdentifier` key is not defined in the bundle’s information property list.")
        }
        guard let groupStorage = UserDefaults(suiteName: "group.\(bundleIdentifier).optimove") else {
            fatalError("If this line is crashing the client forgot to add the app group as described in the documentation.")
        }
        return OptimoveStorageFacade(
            sharedStorage: UserDefaults.standard,
            groupStorage: groupStorage,
            fileStorage: OptimoveFileManager(
                fileManager: .default
            )
        )
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _statisticService: StatisticService = {
        return StatisticServiceImpl()
    }()


    // MARK: - Functions

    func realtimeMetaDataProvider() -> MetaDataProvider<RealtimeMetaData> {
        return _realtimeMetaDataProvider
    }

    func optitrackMetaDataProvider() -> MetaDataProvider<OptitrackMetaData> {
        return _optitrackMetaData
    }

    func optipushMetaDataProvider() -> MetaDataProvider<OptipushMetaData> {
        return _optipushMetaData
    }

    func storage() -> OptimoveStorage {
        return _storage
    }

    func networking() -> NetworkClient {
        return NetworkClientImpl(configuration: .default)
    }

    func warehouseProvider() -> EventsConfigWarehouseProvider {
        return _warehouseProvider
    }

    func deviceStateMonitor() -> OptimoveDeviceStateMonitor {
        return _deviceStateMonitor
    }

    func notificationListener() -> OptimoveNotificationHandling {
        return _notificationListener
    }

    func dateTimeProvider() -> DateTimeProvider {
        return DateTimeProviderImpl()
    }

    func statisticService() -> StatisticService {
        return _statisticService
    }

    func networkClient() -> NetworkClient {
        return NetworkClientImpl()
    }

}
