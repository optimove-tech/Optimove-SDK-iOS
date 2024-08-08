import Foundation
import OptimoveCore

enum TenantIDError: Error {
    case conversionFailed
}

@available(iOS 13.0, *)
class PreferenceCenter {
    private var networkClient: NetworkClient
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage, networkClient: NetworkClient) {
        self.networkClient = networkClient
        self.storage = storage
    }

    func getPreferences(brandGroupId: String) async throws -> Preferences {
        // TODO: resolve region business
        let region = "dev"
        let tenantId = try storage.getTenantID().description
        let customerId = try storage.getCustomerID()

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

    func setPreferences(for _: String, brandGroupId: String, updates preferenceUpdates: [PreferenceUpdateRequest]) async throws -> Preferences {
        do {
            // TODO: resolve region business
            let region = "dev"
            let tenantId = try storage.getTenantID().description
            let customerId = try storage.getCustomerID()

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
            print("Failed to create network request: \(error)")
            throw NetworkError.requestFailed
        }
    }
}
