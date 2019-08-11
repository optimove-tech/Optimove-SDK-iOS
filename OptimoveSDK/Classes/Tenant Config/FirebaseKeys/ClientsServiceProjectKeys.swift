import Foundation

final class ClientsServiceProjectKeys: BaseFirebaseKeys, FirebaseKeys {

    private struct Constant {
        static let masterKey = "ios.master.app"
    }
    
    let appid: String

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let appIDsContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .appIds)
        let iosContainer = try appIDsContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .ios)
        let codingKey: RuntimeCodingKey = try cast(RuntimeCodingKey(stringValue: Constant.masterKey))
        appid = try iosContainer.decode(String.self, forKey: codingKey)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var appIDsContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .appIds)
        var iosContainer = appIDsContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .ios)
        let codingKey: RuntimeCodingKey = try cast(RuntimeCodingKey(stringValue: Constant.masterKey))
        try iosContainer.encode(appid, forKey: codingKey)
        try super.encode(to: encoder)
    }
}
