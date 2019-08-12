// Copiright 2019 Optimove

import Foundation

public struct NetworkResponse<Body> {
    let statusCode: Int
    let body: Body
}

extension NetworkResponse where Body == Data? {

    public func decode<BodyType: Decodable>(to type: BodyType.Type) throws -> BodyType {
        let data = try unwrap()
        return try JSONDecoder().decode(BodyType.self, from: data)
    }

    public func unwrap() throws -> Data  {
        guard let data = body else {
            throw NetworkError.noData
        }
        return data
    }

}
