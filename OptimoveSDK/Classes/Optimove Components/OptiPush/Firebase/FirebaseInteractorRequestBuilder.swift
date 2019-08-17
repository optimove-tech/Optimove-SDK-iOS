//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class FirebaseInteractorRequestBuilder {

    private struct Path {
        static let register = "registerClientToTopics"
        static let unregister = "unregisterClientFromTopics"
    }

    private let storage: OptimoveStorage
    private let configuration: OptipushConfig

    init(storage: OptimoveStorage,
         configuration: OptipushConfig) {
        self.storage = storage
        self.configuration = configuration
    }


    func createUnsubscribeRequest(topic: String) throws -> NetworkRequest {
        let baseURL = configuration.pushTopicsRegistrationEndpoint.appendingPathComponent(Path.unregister)
        let body = RequestBody(
            fcmToken: try storage.getFcmToken(),
            topics: [topic]
        )
        return try NetworkRequest(method: .post, baseURL: baseURL, body: body)
    }

    func createSubscribeRequest(topic: String) throws -> NetworkRequest {
        let baseURL = configuration.pushTopicsRegistrationEndpoint.appendingPathComponent(Path.register)
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
