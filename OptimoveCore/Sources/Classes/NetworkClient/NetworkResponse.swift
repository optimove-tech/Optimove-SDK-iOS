//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct NetworkResponse<Body> {
    let statusCode: Int
    let body: Body
}

public extension NetworkResponse where Body == Data? {

    func decode<BodyType: Decodable>(to type: BodyType.Type) throws -> BodyType {
        let data = try unwrap()
        return try JSONDecoder().decode(BodyType.self, from: data)
    }

    func unwrap() throws -> Data {
        guard let data = body else {
            throw NetworkError.noData
        }
        return data
    }

}
