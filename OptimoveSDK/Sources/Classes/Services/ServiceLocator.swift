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
    private let _storage: StorageFacade

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

    /// Keeps as singleton in reason to share a session state between a service consumers.
    private lazy var _locationManager: LocationService = {
        return LocationServiceImpl()
    }()

    private lazy var _deviceStateObserver: DeviceStateObserver = {
        return DeviceStateObserverFactory(
            statisticService: statisticService(),
            synchronizer: synchronizer(),
            optInService: optInService(),
            dateTimeProvider: dateTimeProvider(),
            coreEventFactory: coreEventFactory(),
            storage: storage()
        ).build()
    }()

    /// MARK: - Initializer

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

    func configurationFetcher() -> ConfigurationFetcher {
        return ConfigurationFetcher(
            operationFactory: operationFactory(),
            configurationRepository: configurationRepository()
        )
    }

    func initializer() -> SDKInitializer {
        return SDKInitializer(
            componentFactory: componentFactory(),
            chainMutator: _synchronizer,
            dependencies: [
                OptimoveStrorageSDKInitializerDependency(storage: storage()),
                MultiplexLoggerStreamSDKInitializerDependency()
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

    func optInService() -> OptInService {
        return OptInService(
            synchronizer: synchronizer(),
            coreEventFactory: coreEventFactory(),
            storage: storage(),
            subscribers: []
        )
    }

    func deviceStateObserver() -> DeviceStateObserver {
        return _deviceStateObserver
    }

    /// MARK: - Factories

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

    func registrar(configuration: Configuration) -> Registrable {
        let requestFactory = ApiRequestFactory(
            storage: storage(),
            payloadBuilder: ApiPayloadBuilder(
                storage: storage(),
                appNamespace: try! Bundle.getApplicationNameSpace()
            ),
            requestBuilder: ApiRequestBuilder(
                optipushConfig: configuration.optipush
            )
        )
        let apiNetworking = ApiNetworkingImpl(
            networkClient: networking(),
            requestFactory: requestFactory
        )
        return Registrar(
            storage: storage(),
            networking: apiNetworking
        )
    }

}
