// Copiright 2019 Optimove

import Foundation

protocol RegistrarNetworking {
    func sendToMbaas(model: BaseMbaasModel, completion: @escaping (Result<String, Error>) -> Void)
}

final class RegistrarNetworkingImpl {

    private let networkClient: NetworkClient
    private let requestBuilder: RegistrarNetworkingRequestBuilder

    init(networkClient: NetworkClient,
         requestBuilder: RegistrarNetworkingRequestBuilder) {
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
    }

}

extension RegistrarNetworkingImpl: RegistrarNetworking {

    func sendToMbaas(model: BaseMbaasModel, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let request = try requestBuilder.createRequest(model: model)
            if let httpBody = request.httpBody, let json = String(data: httpBody, encoding: .utf8) {
                OptiLoggerMessages.logSendMbaasRequest(url: request.baseURL, json: json)
            }
            networkClient.perform(request) { (result) in
                completion(
                    Result {
                        do {
                            let data = try result.get().unwrap()
                            let string: String = try cast(String(data: data, encoding: .utf8))
                            OptiLoggerMessages.logMbaasResponse(
                                mbaasRequestOperation: model.operation.rawValue,
                                response: string
                            )
                            return string
                        } catch {
                            OptiLoggerMessages.logMbaasRequestError(
                                mbaasRequestOperation: model.operation.rawValue,
                                errorDescription: error.localizedDescription
                            )
                            throw error
                        }
                    }
                )
            }
        } catch {
            completion(.failure(error))
        }
    }
}
