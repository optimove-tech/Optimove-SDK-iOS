//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public protocol OptistreamNetworking {
    func send(events: [OptistreamEvent], completion: @escaping (Result<Void, NetworkError>) -> Void)
}

public final class OptistreamNetworkingImpl {

    private let networkClient: NetworkClient
    private let endpoint: URL

    public init(
        networkClient: NetworkClient,
        endpoint: URL
    ) {
        self.networkClient = networkClient
        self.endpoint = endpoint
    }

}

extension OptistreamNetworkingImpl: OptistreamNetworking {

    public func send(events: [OptistreamEvent], completion: @escaping (Result<Void, NetworkError>) -> Void) {
        do {
            let request = try NetworkRequest(
                method: .post,
                baseURL: endpoint,
                body: events
            )
            networkClient.perform(request) {
                OptistreamNetworkingImpl.handleResult(result: $0, for: events, completion: completion)
            }
        } catch {
            completion(.failure(NetworkError.error(error)))
        }
    }

}

private extension OptistreamNetworkingImpl {

    static func handleResult(result: Result<NetworkResponse<Data?>, NetworkError>,
                             for events: [OptistreamEvent],
                             completion: @escaping (Result<Void, NetworkError>) -> Void) {
        do {
            let response = try result.get()
            Logger.debug(
                """
                Optistream succeed:
                    request: \n\(events.map { $0.event }.joined(separator: "\n"))
                    response: \n\(response)
                """
            )
            completion(.success(()))
        } catch {
            Logger.error(
                """
                Optistream failed:
                    request: \n\(events.map { $0.event }.joined(separator: "\n"))
                    reason: \n\(error.localizedDescription)
                """
            )
            completion(.failure(NetworkError.error(error)))
        }
    }

}
