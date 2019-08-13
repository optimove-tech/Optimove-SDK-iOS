// Copiright 2019 Optimove

import Foundation

enum NetworkResult<Body> {
    case success(NetworkResponse<Body>)
    case failure(NetworkError)
}
