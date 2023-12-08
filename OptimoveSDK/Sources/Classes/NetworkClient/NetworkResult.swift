//  Copyright © 2019 Optimove. All rights reserved.

enum NetworkResult<Body> {
    case success(NetworkResponse<Body>)
    case failure(NetworkError)
}
