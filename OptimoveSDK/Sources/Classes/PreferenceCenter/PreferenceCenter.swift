import Foundation
import OptimoveCore

public enum PreferenceCenterNamespace {

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
        private var storage: OptimoveStorage?

        static var isSdkRunning: Bool {
            return PreferenceCenter.instance?.config != nil
        }

        static func initialize(config optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient ) throws {
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

        public static func getPreferences() async throws -> Preferences {
            guard let instance = PreferenceCenter.instance,
                  let config = instance.config,
                  let storage = instance.storage,
                  let networkClient = instance.networkClient
            else {
                throw PreferenceCenter.Error.configurationIsMissing
            }

            do {
                let customerId = try storage.getCustomerID()
                let region = config.region
                let brandGroupId = config.brandGroupId
                let tenantId = config.tenantId.description

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

        public static func setPreferences(updates preferenceUpdates: [PreferenceUpdateRequest]) async throws -> Preferences {
            do {
                guard
                    let instance = PreferenceCenter.instance,
                    let config = instance.config,
                    let storage = instance.storage,
                    let networkClient = instance.networkClient
                else {
                    throw PreferenceCenter.Error.configurationIsMissing
                }


                let customerId = try storage.getCustomerID()

                let region = config.region
                let brandGroupId = config.brandGroupId
                let tenantId = config.tenantId.description

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
}
