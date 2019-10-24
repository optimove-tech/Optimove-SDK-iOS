//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class MockRegistrarNetworking: RegistrarNetworking {

    var assertFunction: ((MbaasOperation) -> Result<String, Error>) = { _ in
        return .success("")
    }

    func sendToMbaas(operation model: MbaasOperation, completion: @escaping (Result<String, Error>) -> Void) {
        completion(assertFunction(model))
    }

}
