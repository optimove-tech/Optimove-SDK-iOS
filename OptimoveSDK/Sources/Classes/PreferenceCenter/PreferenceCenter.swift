import Foundation
import OptimoveCore

enum TenantIDError: Error {
    case conversionFailed
}

@available(iOS 13.0, *)
public class PreferenceCenter {
    enum Error: LocalizedError {
        case alreadyInitialized
        case configurationIsMissing

        var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The OptimobileSDK has already been initialized."
            case .configurationIsMissing:
                return "OptimobileConfig is missing."
            }
        }
    }

    fileprivate static var instance: PreferenceCenter?
    private(set) var config: PreferenceCenterConfig?

    private  var networkClient: NetworkClient?
    private var storage: OptimoveStorage

    static var isSdkRunning: Bool {
        return PreferenceCenter.instance?.config != nil
    }

    static func initialize(config optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient ) throws {
        if instance !== nil,
           optimoveConfig.features.contains(.delayedConfiguration)
        {
            try completeDelayedConfiguration(config: optimoveConfig.preferenceCenterConfig!)
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }


        guard let config = optimoveConfig.preferenceCenterConfig else {
            throw Error.configurationIsMissing
        }

        instance = PreferenceCenter(config: config, storage: storage, networkClient: networkClient)
    }


    private init(config: PreferenceCenterConfig, storage: OptimoveStorage, networkClient: NetworkClient) {
        self.config = config
        self.networkClient = networkClient
        self.storage = storage

        Logger.debug("Preference center SDK was initialized with \(config)")
    }

    static func completeDelayedConfiguration(config: PreferenceCenterConfig) throws {
        //Question: Do i need to do anything here for this?
        Logger.info("complete Delayed Configuration")
    }

    static func getPreferences(config: PreferenceCenterConfig) async throws -> Preferences {
        //Q: How do I actually use the config, I know I shouldn't be passing it as an arg, but it doesn't let me use it, same with storage.
        do {
            let region = "dev" //TODO: Use config
            let customerId = "daniela-customer"
            // let customerId = try storage.getCustomerID() // Q: why can't I use storage?

            let brandGroupId = config.brandGroupId
            let tenantId = config.tenantId.description
            let networkClient = NetworkClientImpl()

            let request = NetworkRequest(
                method: .get,
                baseURL: URL(string: "https://preference-center-\(region).optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
                ],
                queryItems: [
                    URLQueryItem(name: "customerId", value: customerId),
                    URLQueryItem(name: "brandGroupId", value: brandGroupId)
                ]
            )

            let data: Data = try cast(await networkClient.performAsync(request))
            return try JSONDecoder().decode(Preferences.self, from: data)
        }
        catch {
            throw NetworkError.requestFailed
        }
    }

      static func setPreferences(config: PreferenceCenterConfig, updates preferenceUpdates: [PreferenceUpdateRequest]) async throws -> Preferences {
         do {
            
             let region = "dev" //TODO: Use config
             let customerId = "daniela-customer"
             // let customerId = try storage.getCustomerID() // Q: why can't I use storage?

             let brandGroupId = config.brandGroupId
             let tenantId = config.tenantId.description
             let networkClient = NetworkClientImpl()

            let request = try NetworkRequest(
                method: .put,
                baseURL: URL(string: "https://preference-center-\(region).optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
                ],
                queryItems: [
                    URLQueryItem(name: "customerId", value: customerId),
                    URLQueryItem(name: "brandGroupId", value: brandGroupId)
                ],
                body: preferenceUpdates
            )


            let data: Data = try cast(await networkClient.performAsync(request))
            let preferences = try JSONDecoder().decode(Preferences.self, from: data)

            return preferences
        }
        catch {
            throw NetworkError.requestFailed
        }
    }
}
