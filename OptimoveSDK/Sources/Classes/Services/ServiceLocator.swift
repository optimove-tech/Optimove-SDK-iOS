//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ServiceLocator {
    // MARK: - Singletons

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private let _storage: StorageFacade

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _statisticService: StatisticService = StatisticServiceImpl()

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _pipelineSinglton: PipelineMutator = PipelineImpl(
        pipe: InMemoryBuffer()
    )

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _locationManager: LocationService = LocationServiceImpl()

    private lazy var _deviceStateObserver: DeviceStateObserver = DeviceStateObserverFactory(
        statisticService: statisticService(),
        synchronizer: pipeline(),
        dateTimeProvider: dateTimeProvider(),
        coreEventFactory: coreEventFactory(),
        storage: storage()
    ).build()

    // MARK: - Initializer

    init(storageFacade: StorageFacade) {
        _storage = storageFacade
    }

    // MARK: - Functions

    func storage() -> OptimoveStorage {
        return _storage
    }

    func networking() -> NetworkClient {
        return NetworkClientImpl(configuration: .default)
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

    func pipeline() -> Pipeline {
        return _pipelineSinglton
    }

    func configurationFetcher() -> ConfigurationFetcher {
        return ConfigurationFetcher(
            operationFactory: operationFactory(),
            configurationRepository: configurationRepository()
        )
    }

    func initializer() -> SDKInitializer {
        return SDKInitializer(
            componentFactory: componentFactory(),
            pipeline: _pipelineSinglton,
            dependencies: [
                OptimoveStrorageSDKInitializerDependency(storage: storage()),
                MultiplexLoggerStreamSDKInitializerDependency(),
            ],
            storage: storage()
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

    func firstTimeVisitGenerator() -> FirstRunTimestampGenerator {
        return FirstRunTimestampGenerator(storage: storage())
    }

    func installationIdGenerator() -> InstallationIdGenerator {
        return InstallationIdGenerator(storage: storage())
    }

    func deviceStateObserver() -> DeviceStateObserver {
        return _deviceStateObserver
    }

    // MARK: - Factories

    func componentFactory() -> ComponentFactory {
        return ComponentFactory(
            serviceLocator: self,
            coreEventFactory: coreEventFactory()
        )
    }

    func coreEventFactory() -> CoreEventFactory {
        return CoreEventFactoryImpl(
            storage: storage(),
            dateTimeProvider: dateTimeProvider(),
            locationService: _locationManager
        )
    }

    func networkingFactory() -> NetworkingFactory {
        return NetworkingFactory(
            networkClient: NetworkClientImpl(),
            requestBuilderFactory: NetworkRequestBuilderFactory(
                serviceLocator: self
            )
        )
    }

    func operationFactory() -> OperationFactory {
        return OperationFactory(
            configurationRepository: configurationRepository(),
            networking: networkingFactory().createRemoteConfigurationNetworking()
        )
    }
}
