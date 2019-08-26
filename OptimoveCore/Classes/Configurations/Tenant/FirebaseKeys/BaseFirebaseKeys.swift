//  Copyright © 2017 Optimove. All rights reserved.

public protocol FirebaseKeys {
    var webApiKey: String { get }
    var dbUrl: String { get }
    var senderId: String { get }
    var storageBucket: String { get }
    var projectId: String { get }
    var appid: String { get }
}

public class BaseFirebaseKeys: Codable {

    public let webApiKey: String
    public let dbUrl: String
    public let senderId: String
    public let storageBucket: String
    public let projectId: String

    public init(webApiKey: String, dbUrl: String, senderId: String, storageBucket: String, projectId: String) {
        self.webApiKey = webApiKey
        self.dbUrl = dbUrl
        self.senderId = senderId
        self.storageBucket = storageBucket
        self.projectId = projectId
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        webApiKey = try values.decode(String.self, forKey: .webApiKey)
        dbUrl = try values.decode(String.self, forKey: .dbUrl)
        senderId = try values.decode(String.self, forKey: .senderId)
        storageBucket = try values.decode(String.self, forKey: .storageBucket)
        projectId = try values.decode(String.self, forKey: .projectId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(webApiKey, forKey: .webApiKey)
        try container.encode(dbUrl, forKey: .dbUrl)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(storageBucket, forKey: .storageBucket)
        try container.encode(projectId, forKey: .projectId)
    }
}

extension BaseFirebaseKeys {

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
}

extension BaseFirebaseKeys: Equatable {

    public static func == (lhs: BaseFirebaseKeys, rhs: BaseFirebaseKeys) -> Bool {
        return lhs.webApiKey == rhs.webApiKey &&
            lhs.dbUrl == rhs.dbUrl &&
            lhs.senderId == rhs.senderId &&
            lhs.storageBucket == rhs.storageBucket &&
            lhs.projectId == rhs.projectId
    }

}
