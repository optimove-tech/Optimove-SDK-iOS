//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ServiceLocator {

    // MARK: - Singletons

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _deeplinkService: DeeplinkService = {
        return DeeplinkService()
    }()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _storage: StorageFacade = {
        do {
            let bundleIdentifier = try Bundle.getApplicationNameSpace()
            let groupStorage = try UserDefaults.grouped(tenantBundleIdentifier: bundleIdentifier)
            let fileStorage = try FileStorageImpl(bundleIdentifier: bundleIdentifier, fileManager: .default)
            return StorageFacade(
                groupedStorage: groupStorage,
                sharedStorage: UserDefaults.standard,
                fileStorage: fileStorage
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
    private lazy var _synchronizer: Synchronizer = {
        return SynchronizerImpl(
            chain: Chain(
                next: InMemoryBuffer()
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

    func notificationListener() -> OptimoveNotificationHandling {
        return OptimoveNotificationHandler(
            synchronizer: synchronizer(),
            deeplinkService: deeplinkService()
        )
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

    func synchronizer() -> Synchronizer {
        return _synchronizer
    }

    func configurationFetcher(operationFactory: OperationFactory) -> ConfigurationFetcher {
        return ConfigurationFetcher(
            operationFactory: operationFactory,
            configurationRepository: configurationRepository()
        )
    }

    func initializer(componentFactory: ComponentFactory) -> SDKInitializer {
        return SDKInitializer(
            storage: storage(),
            componentFactory: componentFactory,
            chainMutator: _synchronizer
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

    func firstTimeVisitGenerator() -> FirstTimeVisitGenerator {
        return FirstTimeVisitGenerator(storage: storage())
    }

    func installationIdGenerator() -> InstallationIdGenerator {
        return InstallationIdGenerator(storage: storage())
    }

    func optInService(coreEventFactory: CoreEventFactory) -> OptInService {
        return OptInService(
            synchronizer: synchronizer(),
            coreEventFactory: coreEventFactory,
            storage: storage()
        )
    }

    func deviceStateObserver(coreEventFactory: CoreEventFactory) -> DeviceStateObserver {
        return DeviceStateObserver(
            observers: [
                ResignActiveObserver(
                    subscriber: synchronizer()
                ),
                OptInOutObserver(
                    optInService: optInService(coreEventFactory: coreEventFactory),
                    notificationPermissionFetcher: NotificationPermissionFetcherImpl()
                ),
                AppOpenObserver(
                    synchronizer: synchronizer(),
                    statisticService: statisticService(),
                    dateTimeProvider: dateTimeProvider(),
                    coreEventFactory: coreEventFactory
                )
            ]
        )
    }

}
