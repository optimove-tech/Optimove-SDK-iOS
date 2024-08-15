import Foundation
import OptimoveCore

@available(iOS 13.0, *)
public class OptimovePreferenceCenter {
    enum Error: LocalizedError {
        case alreadyInitialized
        case notInitialized

        var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The PreferenceCenterSDK has already been initialized."
            case .notInitialized:
                return "Preference center has not been initialized."
            }
        }
    }

    private static var instance: OptimovePreferenceCenter?
    private var networkClient: NetworkClient?
    private var storage: OptimoveStorage?

    static var isSdkRunning: Bool {
        return Optimove.getConfig()?.getPreferenceCenterConfig() != nil
    }

    public enum ResultType {
        case success
        case errorUserNotSet
        case errorNotConfigured
        case error
    }

    public typealias PreferencesGetHandler = (_ result: ResultType, _ preferences: Preferences?) -> Void
    public typealias PreferencesSetHandler = (_ result: ResultType) -> Void

    public static func getInstance() throws -> OptimovePreferenceCenter {
        guard let instance = instance else {
            throw Error.notInitialized
        }
        return instance
    }

    static func initialize(storage: OptimoveStorage, networkClient: NetworkClient) throws {
        guard instance == nil else {
            throw Error.alreadyInitialized
        }

        instance = OptimovePreferenceCenter(storage: storage, networkClient: networkClient)
    }

    private init(storage: OptimoveStorage, networkClient: NetworkClient) {
        self.networkClient = networkClient
        self.storage = storage

        Logger.debug("Preference center SDK was initialized")
    }

    public func getPreferencesAsync(completion: @escaping PreferencesGetHandler) {
        guard let config = Optimove.getConfig()?.getPreferenceCenterConfig() else {
            Logger.error("Preference center credentials are not set")
            completion(.errorNotConfigured, nil)
            return
        }

        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId
        else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet, nil)
            return
        }

        Task {
            do {
                let request = createGetPreferencesRequest(for: customerId, with: config)
                let data = try await networkClient?.performAsync(request) ?? Data()
                let preferences = try JSONDecoder().decode(Preferences.self, from: data)

                DispatchQueue.main.async {
                    completion(.success, preferences)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.error, nil)
                }
            }
        }
    }

    private func createGetPreferencesRequest(for customerId: String, with config: PreferenceCenterConfig) -> NetworkRequest {
        do {
            let (region, brandGroupId, tenantId) = try getConfigValues(from: config)

            return NetworkRequest(
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
        } catch {
            fatalError("Configuration is missing. This should never happen if the SDK is initialized properly.")
        }
    }

    private func getConfigValues(from config: PreferenceCenterConfig) throws -> (region: String, brandGroupId: String, tenantId: String) {
        let region = config.region
        let brandGroupId = config.brandGroupId
        let tenantId = config.tenantId.description
        return (region, brandGroupId, tenantId)
    }


    public func setPreferencesAsync(updates: [PreferenceUpdate], completion: @escaping PreferencesSetHandler) {
        guard let config = Optimove.getConfig()?.getPreferenceCenterConfig() else {
            Logger.error("Preference center credentials are not set")
            completion(.errorNotConfigured)
            return
        }

        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet)
            return
        }

        Task {
            do {
                let request = try createSetPreferencesRequest(for: customerId, with: config, updates: updates)
                _ = try await networkClient?.performAsync(request)
                
                DispatchQueue.main.async {
                    completion(.success)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.error)
                }
            }
        }
    }

    private func createSetPreferencesRequest(
        for customerId: String,
        with config: PreferenceCenterConfig,
        updates: [PreferenceUpdate]) throws -> NetworkRequest {
        let (region, brandGroupId, tenantId) = try getConfigValues(from: config)

        return try NetworkRequest(
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
            body: updates
        )
    }

    private func logFailedResponse(_ error: Swift.Error) {
        Logger.error("Request failed with error: \(error.localizedDescription)")
    }

    private func logFailedResponse(_ response: URLResponse) {
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 400:
                Logger.error("Status code 400: check preference center configuration")
            default:
                Logger.error("Request failed with status code: \(httpResponse.statusCode)")
            }
        }
    }
}
