//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class MockRegistrarNetworking: ApiNetworking {

    var assertFunction: ((ApiOperation) -> Result<String, Error>) = { _ in
        return .success("")
    }

    func sendToMbaas(operation model: ApiOperation, completion: @escaping (Result<String, Error>) -> Void) {
        completion(assertFunction(model))
    }

}
