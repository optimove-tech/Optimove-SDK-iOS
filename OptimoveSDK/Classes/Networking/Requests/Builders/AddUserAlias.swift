//  Copyright © 2020 Optimove. All rights reserved.

struct AddUserAlias: Codable {

    let newAliases: [String]

    enum CodingKeys: String, CodingKey {
        case newAliases = "new_aliases"
    }
}
