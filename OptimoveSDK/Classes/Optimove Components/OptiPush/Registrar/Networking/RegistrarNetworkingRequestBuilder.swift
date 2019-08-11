// Copiright 2019 Optimove

import Foundation

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
    private let metaData: OptipushMetaData
    private let encoder: JSONEncoder

    init(storage: OptimoveStorage,
         metaData: OptipushMetaData) {
        self.storage = storage
        self.metaData = metaData
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
        switch model.operation {
        case .registration:
            return metaData.registrationServiceRegistrationEndPoint
                .appendingPathComponent(Constants.Path.Operation.register + suffix)
        case .unregistration:
            return metaData.registrationServiceOtherEndPoint
                .appendingPathComponent(Constants.Path.Operation.unregister + suffix)
        case .optIn, .optOut:
            return metaData.registrationServiceOtherEndPoint
                .appendingPathComponent(Constants.Path.Operation.optInOut + suffix)
        }
    }
}
