//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct NetworkResponse<Body> {
    let statusCode: Int
    let body: Body
}

extension NetworkResponse where Body == Data? {
    func decode<BodyType: Decodable>(to _: BodyType.Type) throws -> BodyType {
        let data = try unwrap()
        return try JSONDecoder().decode(BodyType.self, from: data)
    }

    func unwrap() throws -> Data {
        guard let data = body else {
            throw NetworkError.noData
        }
        return data
    }

    var description: String {
        do {
            let body = try unwrap()
            guard let decodedBody = String(data: body, encoding: .utf8) else {
                return "no body"
            }
            return decodedBody
        } catch {
            return error.localizedDescription
        }
    }
}
