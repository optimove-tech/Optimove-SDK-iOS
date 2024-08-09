import Foundation
import OptimoveCore

@available(iOS 13.0, *)
public class OptimovePreferenceCenter {
    enum Error: LocalizedError {
        case alreadyInitialized
        case configurationIsMissing

        var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The PreferenceCenterSDK has already been initialized."
            case .configurationIsMissing:
                return "Preference center config is missing."
            }
        }
    }

    private static var instance: OptimovePreferenceCenter?
    private var config: PreferenceCenterConfig?
    private var networkClient: NetworkClient?
    private var storage: OptimoveStorage?

    static var isSdkRunning: Bool {
        return OptimovePreferenceCenter.instance?.config != nil
    }

    public enum ResultType {
        case success
        case errorUserNotSet
        case error
    }

    public typealias PreferencesGetHandler = (_ result: ResultType, _ preferences: Preferences?) -> Void
    public typealias PreferencesSetHandler = (_ result: ResultType) -> Void

    public static func getInstance() throws -> OptimovePreferenceCenter {
        guard let instance = instance else {
            throw Error.configurationIsMissing
        }
        return instance
    }
    
    static func initialize(config optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient) throws {
        guard instance == nil else {
            throw Error.alreadyInitialized
        }

        guard let config = optimoveConfig.preferenceCenterConfig else {
            throw Error.configurationIsMissing
        }

        instance = OptimovePreferenceCenter(config: config, storage: storage, networkClient: networkClient)
    }

    private init(config: PreferenceCenterConfig, storage: OptimoveStorage, networkClient: NetworkClient) {
        self.config = config
        self.networkClient = networkClient
        self.storage = storage

        Logger.debug("Preference center SDK was initialized with \(config)")
    }

    public func getPreferencesAsync(completion: @escaping PreferencesGetHandler) {
        guard let customerId = try? storage?.getCustomerID() else {
            completion(.errorUserNotSet, nil)
            return
        }

        Task {
            do {
                let preferences = try await self.fetchPreferences(customerId: customerId)
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

    private func fetchPreferences(customerId: String) async throws -> Preferences {
        guard config != nil else { throw Error.configurationIsMissing }

        let request = createGetPreferencesRequest(customerId: customerId)
        let data = try await networkClient?.performAsync(request) ?? Data()

        return try JSONDecoder().decode(Preferences.self, from: data)
    }

    private func createGetPreferencesRequest(customerId: String) -> NetworkRequest {
        let region = config?.region ?? ""
        let brandGroupId = config?.brandGroupId ?? ""
        let tenantId = config?.tenantId.description ?? ""

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
    }

    public func setPreferencesAsync(updates: [PreferenceUpdateRequest], completion: @escaping PreferencesSetHandler) {
        guard let customerId = try? storage?.getCustomerID() else {
            completion(.errorUserNotSet)
            return
        }

        Task {
            do {
                try await self.sendPreferences(customerId: customerId, updates: updates)
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

    private func sendPreferences(customerId: String, updates: [PreferenceUpdateRequest]) async throws {
        guard config != nil else { throw Error.configurationIsMissing }

        let request = try createSetPreferencesRequest(customerId: customerId, updates: updates)
        _ = try await networkClient?.performAsync(request)
    }

    private func createSetPreferencesRequest(customerId: String, updates: [PreferenceUpdateRequest]) throws -> NetworkRequest {
        let region = config?.region ?? ""
        let brandGroupId = config?.brandGroupId ?? ""
        let tenantId = config?.tenantId.description ?? ""

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
