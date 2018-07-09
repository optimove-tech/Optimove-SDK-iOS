
import Foundation


class ClientsServiceProjectKeys: FirebaseKeys
{
    var appid:String
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let appIds = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .appIds)
        let ios = try appIds.nestedContainer(keyedBy: CK.self, forKey: .ios)
        appid = try ios.decode(String.self, forKey: CK(stringValue:"ios.master.app")!)
        try super.init(from: decoder)
    }
}
