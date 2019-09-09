//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ServiceLocator {

    // MARK: - Singletons

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _deviceStateMonitor: OptimoveDeviceStateMonitor = {
        return OptimoveDeviceStateMonitorImpl(
            fetcherFactory: DeviceRequirementFetcherFactoryImpl()
        )
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _deeplinkService: DeeplinkService = {
        return DeeplinkService()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _notificationListener: OptimoveNotificationHandler = {
        return OptimoveNotificationHandler(
            storage: storage(),
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage(),
                dateTimeProvider: dateTimeProvider()
            ),
            handlersPool: handlersPool(),
            deeplinkService: deeplinkService()
        )
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _storage: StorageFacade = {
        do {
            let bundleIdentifier = try Bundle.getApplicationNameSpace()
            let groupStorage = try UserDefaults.grouped(tenantBundleIdentifier: bundleIdentifier)
            return StorageFacade(
                groupedStorage: groupStorage,
                sharedStorage: UserDefaults.standard,
                fileStorage: try FileStorageImpl(
                    bundleIdentifier: bundleIdentifier,
                    fileManager: .default
                )
            )
        } catch {
            fatalError(error.localizedDescription)
        }
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _statisticService: StatisticService = {
        return StatisticServiceImpl()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _handlersPool: HandlersPool = {
        return HandlersPool(
            eventableHandler: InMemoryBuffer<EventableOperationContext>(
                storage: storage()
            ),
            pushableHandler: InMemoryBuffer<PushableOperationContext>(
                storage: storage()
            )
        )
    }()

    // MARK: - Functions

    func storage() -> OptimoveStorage {
        return _storage
    }

    func networking() -> NetworkClient {
        return NetworkClientImpl(configuration: .default)
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

    func configurationRepository() -> ConfigurationRepository {
        return ConfigurationRepositoryImpl(storage: storage())
    }

    func deeplinkService() -> DeeplinkService {
        return _deeplinkService
    }

    func handlersPool() -> HandlersPool {
        return _handlersPool
    }

    func configurationFetcher(operationFactory: OperationFactory) -> ConfigurationFetcher {
        return ConfigurationFetcher(
            operationFactory: operationFactory,
            configurationRepository: configurationRepository()
        )
    }

    func initializer(componentFactory: ComponentFactory) -> OptimoveSDKInitializer {
        return OptimoveSDKInitializer(
            storage: storage(),
            componentFactory: componentFactory,
            handlersPool: handlersPool()
        )
    }

    func loggerInitializator() -> LoggerInitializator {
        return LoggerInitializator(storage: storage())
    }

    func newTenantInfoHandler() -> NewTenantInfoHandler {
        return NewTenantInfoHandler(storage: storage())
    }

    func newVisitorIdGenerator() -> NewVisitorIdGenerator {
        return NewVisitorIdGenerator(storage: storage())
    }

}
