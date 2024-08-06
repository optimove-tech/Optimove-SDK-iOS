import Foundation
import OptimoveCore

enum TenantIDError: Error {
    case conversionFailed
}

@available(iOS 13.0, *)
class PreferenceCenter {
    private var networkClient: NetworkClient
    private var storage: KeyValueStorage

    init(storage: KeyValueStorage, networkClient: NetworkClient) {
        self.networkClient = networkClient
        self.storage = storage
    }

    private func getTenantId() throws -> String {
        do {
            guard let tenantId: Int = try storage[.tenantID] else {
                throw StorageError.noValue(.tenantID)
            }

            return String(tenantId)
        } catch {
            throw TenantIDError.conversionFailed
        }
    }

    private func getCustomerId() throws -> String {
        guard let customerId: String = try storage[.customerID] else {
            throw StorageError.noValue(.customerID)
        }

        return String(customerId)
    }

    func getPreferences(brandGroupId: String) async throws -> Preferences {
        do {
            //TODO: resolve this
            self.storage.set(value: "daniela-customer", key: .customerID)
            self.storage.set(value: 3013, key: .tenantID)

            let customerId = try getCustomerId()
            let tenantId = try getTenantId()

            let request = try NetworkRequest(
                method: .get,
                baseURL: URL(string: "https://preference-center-dev-pb.optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
                ],
                queryItems:[
                    URLQueryItem(name: "customerId", value: customerId),
                    URLQueryItem(name: "brandGroupId", value: brandGroupId)
                ]
            )


            let data: Data = try cast(await networkClient.performAsync(request))
            let preferences = try JSONDecoder().decode(Preferences.self, from: data)

            return preferences
        }
        catch {
            print("Failed to create network request: \(error)")
        }

        throw NetworkError.requestFailed
    }


    func setPreferences(for customerId: String, brandGroupId: String, updates preferenceUpdates : [PreferenceUpdate]) async throws -> Preferences {
        do {
            // TODO: resolve this
            self.storage.set(value: "daniela-customer", key: .customerID)
            self.storage.set(value: 3013, key: .tenantID)

            let customerId = try getCustomerId()
            let tenantId = try getTenantId()

            let request = try NetworkRequest(
                method: .put,
                baseURL: URL(string: "https://preference-center-dev-pb.optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
                ],
                queryItems:[
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

