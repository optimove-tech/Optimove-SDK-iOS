// Copiright 2019 Optimove

import Foundation
import OptimoveCore

final class RegistrarNetworkingRequestBuilder {

    struct Constants {
        struct Path {
            struct Operation {
                static let register = "register"
                static let unregister = "unregister"
                static let optInOut = "optInOut"
            }
            struct Suffix {
                static let visitor = "Visitor"
                static let customer = "Customer"
            }
        }
    }

    private let storage: OptimoveStorage
    private let configuration: OptipushConfig
    private let encoder: JSONEncoder

    init(storage: OptimoveStorage,
         configuration: OptipushConfig) {
        self.storage = storage
        self.configuration = configuration
        self.encoder = JSONEncoder()
    }

    func createRequest(model: BaseMbaasModel) throws -> NetworkRequest {
        return NetworkRequest(
            method: .post,
            baseURL: createURL(model),
            headers: [
                HTTPHeader(field: .contentType, value: .json)
            ],
            httpBody: try encoder.encode(model)
        )
    }

    private func createURL(_ model: BaseMbaasModel) -> URL {
        let suffix: String = {
            switch model.userIdPayload {
            case .visitorID(_):
                return Constants.Path.Suffix.visitor
            case .customerID(_):
                return Constants.Path.Suffix.customer
            }
        }()
        let path: String = {
            switch model.operation {
            case .registration:
                return Constants.Path.Operation.register
            case .unregistration:
                return Constants.Path.Operation.unregister
            case .optIn, .optOut:
                return Constants.Path.Operation.optInOut
            }
        }()
        return configuration.registrationServiceEndpoint.appendingPathComponent(path + suffix)
    }
}
