// Copiright 2019 Optimove

import Foundation
import OptimoveCore

protocol FirebaseInteractorNetworking {
    func subscribe(topic: String, completion: @escaping (Result<Void, Error>) -> Void)
    func unsubscribe(topic: String, completion: @escaping (Result<Void, Error>) -> Void)
}

final class FirebaseInteractorNetworkingImpl {

    private let networkClient: NetworkClient
    private let requestBuilder: FirebaseInteractorRequestBuilder

    init(networkClient: NetworkClient,
         requestBuilder: FirebaseInteractorRequestBuilder) {
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
    }
}

extension FirebaseInteractorNetworkingImpl: FirebaseInteractorNetworking {

    func subscribe(topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let request = try requestBuilder.createSubscribeRequest(topic: topic)
            networkClient.perform(request) { (result) in
                completion(
                    result.map { _ in }
                )
            }
        } catch {
            completion(.failure(error))
        }
    }

    func unsubscribe(topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let request = try requestBuilder.createUnsubscribeRequest(topic: topic)
            networkClient.perform(request) { (result) in
                completion(
                    result.map { _ in }
                )
            }
        } catch {
            completion(.failure(error))
        }
    }

}
