//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public protocol OptistreamNetworking {
    func send(
        events: [OptistreamEvent],
        path: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )

    func send(
        events: [OptistreamEvent],
        completion: @escaping (Result<Void, NetworkError>) -> Void
    )
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

    private func _send(
        events: [OptistreamEvent],
        path: String?,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        do {
            let request = try NetworkRequest(
                method: .post,
                baseURL: endpoint,
                path: path,
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

extension OptistreamNetworkingImpl: OptistreamNetworking {
    public func send(
        events: [OptistreamEvent],
        path: String,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        _send(events: events, path: path, completion: completion)
    }

    public func send(
        events: [OptistreamEvent],
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        _send(events: events, path: nil, completion: completion)
    }
}

private extension OptistreamNetworkingImpl {
    static func handleResult(result: Result<NetworkResponse<Data?>, NetworkError>,
                             for events: [OptistreamEvent],
                             completion: @escaping (Result<Void, NetworkError>) -> Void)
    {
        do {
            let response = try result.get()
            Logger.debug(
                """
                Optistream succeed:
                request:
                    \(events.map(\.event).joined(separator: "\n\t"))
                response:
                    status code: \(response.statusCode)
                    body: \(response.description)
                """
            )
            completion(.success(()))
        } catch let NetworkError.requestInvalid(data) {
            let response: () -> String = {
                guard let data = data else { return "no data" }
                return String(decoding: data, as: UTF8.self)
            }
            Logger.error(
                """
                Optistream request invalid:
                    request:
                    \(events.map(\.event).joined(separator: "\n"))
                    reason:
                    \(response())
                """
            )
            completion(.success(()))
        } catch {
            Logger.error(
                """
                Optistream failed:
                    request:
                    \(events.map(\.event).joined(separator: "\n"))
                    reason:
                    \(error.localizedDescription)
                """
            )
            completion(.failure(NetworkError.error(error)))
        }
    }
}
