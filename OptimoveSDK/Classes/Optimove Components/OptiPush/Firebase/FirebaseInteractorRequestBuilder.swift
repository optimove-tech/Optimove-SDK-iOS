// Copiright 2019 Optimove

import Foundation

final class FirebaseInteractorRequestBuilder {

    private struct Path {
        static let register = "registerClientToTopics"
        static let unregister = "unregisterClientFromTopics"
    }

    private let storage: OptimoveStorage
    private let metaDataProvider: MetaDataProvider<OptipushMetaData>

    init(storage: OptimoveStorage,
         metaDataProvider: MetaDataProvider<OptipushMetaData>) {
        self.storage = storage
        self.metaDataProvider = metaDataProvider
    }


    func createUnsubscribeRequest(topic: String) throws -> NetworkRequest {
        let metaData = try metaDataProvider.getMetaData()
        let baseURL = metaData.pushTopicsRegistrationEndpoint.appendingPathComponent(Path.unregister)
        let body = RequestBody(
            fcmToken: try storage.getFcmToken(),
            topics: [topic]
        )
        return try NetworkRequest(method: .post, baseURL: baseURL, body: body)
    }

    func createSubscribeRequest(topic: String) throws -> NetworkRequest {
        let metaData = try metaDataProvider.getMetaData()
        let baseURL = metaData.pushTopicsRegistrationEndpoint.appendingPathComponent(Path.register)
        let body = RequestBody(
            fcmToken: try storage.getFcmToken(),
            topics: [topic]
        )
        return try NetworkRequest(method: .post, baseURL: baseURL, body: body)
    }

}

extension FirebaseInteractorRequestBuilder {
    struct RequestBody: Encodable {
        let fcmToken: String
        let topics: [String]
    }
}
