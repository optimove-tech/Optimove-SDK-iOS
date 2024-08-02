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
        if let tenantIdValue = storage.value(for: .tenantID) as? Int {
            return String(tenantIdValue)
        } else {
            throw TenantIDError.conversionFailed
        }
    }
    
    //attempt 1
    func getPrefs(_ completion: @escaping (Result<Preferences, Error>) -> Void) {
        do {
            let tenantId = try getTenantId()
            
            let request = try NetworkRequest(
                method: .get,
                baseURL: URL(string: "https://preference-center-dev-pb.optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: tenantId)
                ],
                queryItems:[
                    URLQueryItem(name: "customerId", value: "daniela-t"),
                    URLQueryItem(name: "brandGroupId", value: "eba9b5c8-7d18-4912-9af1-f3f2f68f5d87")
                ]
            )
            
            networkClient.perform(request) { result in
                completion(
                    Result {
                        let data = try result.get()
                        let preferences = try data.decode(to: Preferences.self)
                        return preferences
                    }
                )
            }
        } catch {
            print("Failed to create network request: \(error)")
            completion(.failure(error))
        }
    }
    
    
    //attempt 2 I think it's better to go with this
    func getPrefsAsync(for customerId: String, brandGroupId: String) async throws -> Preferences {
        do {
            let tenantId = try getTenantId()
            
            let request = try NetworkRequest(
                method: .get,
                baseURL: URL(string: "https://preference-center-dev-pb.optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: tenantId)
                ],
                queryItems:[
                    URLQueryItem(name: "customerId", value: customerId),
                    URLQueryItem(name: "brandGroupId", value: brandGroupId)
                ]
            )
            
            
            let data = try await networkClient.performAsync(request)
            let preferences = try JSONDecoder().decode(Preferences.self, from: data!)
            return preferences
   
            //           await networkClient.perform(request) { result in
            //                Result {
            //                    let data = try result.get()
            //                    let preferences = try data.decode(to: Preferences.self)
            //                    print(preferences)
            //                    return preferences
            //                }
            //            }
        }
        catch {
            print("Failed to create network request: \(error)")
        }
        
        throw NetworkError.requestFailed
    }
    
    
    func setPrefsAsync(for customerId: String, brandGroupId: String, updates preferenceUpdates : [PreferenceUpdate]) async throws -> Preferences {
        do {
            let tenantId = try getTenantId()
            let request = try NetworkRequest(
                method: .put,
                baseURL: URL(string: "https://preference-center-dev-pb.optimove.net")!,
                path: "/api/v1/preferences",
                headers: [
                    HTTPHeader(field: .accept, value: .textplain),
                    HTTPHeader(field: .tenantId, value: tenantId)
                ],
                queryItems:[
                    URLQueryItem(name: "customerId", value: customerId),
                    URLQueryItem(name: "brandGroupId", value: brandGroupId)
                ],
                body: preferenceUpdates
            )
            
            
            await networkClient.perform(request) { result in
                Result {
                    print(result)
                    let data = try result.get()
                    let preferences = try data.decode(to: Preferences.self)
                    print(preferences)
                    return preferences
                }
            }
        }
        catch {
            print("Failed to create network request: \(error)")
        }
        
        throw NetworkError.requestFailed
    }
    
}

