//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum NetworkResult<Body> {
    case success(NetworkResponse<Body>)
    case failure(NetworkError)
}
