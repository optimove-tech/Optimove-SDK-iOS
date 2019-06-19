import Foundation

class FirebaseKeys: Decodable {
    let webApiKey: String
    let dbUrl: String
    let senderId: String
    let storageBucket: String
    let projectId: String

    enum CodingKeys: String, CodingKey {
        case appIds
        case ios
        case webApiKey
        case dbUrl
        case senderId
        case storageBucket
        case projectId
        case firebaseProjectKeys
        case clientsServiceProjectKeys
    }

    struct CK: CodingKey {
        var intValue: Int?
        var stringValue: String

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
        init?(stringValue: String) { self.stringValue = stringValue }
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        webApiKey = try values.decode(String.self, forKey: .webApiKey)
        dbUrl = try values.decode(String.self, forKey: .dbUrl)
        senderId = try values.decode(String.self, forKey: .senderId)
        storageBucket = try values.decode(String.self, forKey: .storageBucket)
        projectId = try values.decode(String.self, forKey: .projectId)
    }
}
