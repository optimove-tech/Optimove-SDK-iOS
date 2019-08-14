// Copiright 2019 Optimove

import Foundation
@testable import OptimoveSDK

final class MockRegistrarNetworking: RegistrarNetworking {

    var assertFunction: ((BaseMbaasModel) -> Result<String, Error>) = { _ in
        return .success("")
    }

    func sendToMbaas(model: BaseMbaasModel, completion: @escaping (Result<String, Error>) -> Void) {
        completion(assertFunction(model))
    }

}
