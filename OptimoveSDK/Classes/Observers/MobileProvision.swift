//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct MobileProvision: Decodable {

    var entitlements: Entitlements

    private enum CodingKeys : String, CodingKey {
        case entitlements = "Entitlements"
    }

    struct Entitlements: Decodable {
        let apsEnvironment: Environment

        private enum CodingKeys: String, CodingKey {
            case apsEnvironment = "aps-environment"
        }

        enum Environment: String, Decodable {
            case development, production, disabled
        }

        init(apsEnvironment: Environment) {
            self.apsEnvironment = apsEnvironment
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let apsEnvironment: Environment = (try? container.decode(Environment.self, forKey: .apsEnvironment)) ?? .disabled
            self.init(apsEnvironment: apsEnvironment)
        }
    }
}


extension MobileProvision {

    private struct Constants {
        static let startPlistTag = "<plist"
        static let endPlistTag = "</plist>"
    }

    static func read() throws -> MobileProvision {
        let profilePath: String = try unwrap(Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"))
        return try read(from: profilePath)
    }

    static func read(from profilePath: String) throws -> MobileProvision {
        let plistDataString = try String(contentsOfFile: profilePath, encoding: String.Encoding.isoLatin1)
        let extractedPlist: String = try unwrap(scanPlistDataString(plistDataString))
        let plist: Data = try unwrap(extractedPlist.appending(Constants.endPlistTag).data(using: .isoLatin1))
        let decoder = PropertyListDecoder()
        return try decoder.decode(MobileProvision.self, from: plist)
    }

    private static func scanPlistDataString(_ string: String) -> String? {
        let scanner = Scanner(string: string)
        if #available(iOS 13.0, *) {
            guard scanner.scanUpToString(Constants.startPlistTag) != nil else { return nil }
            return scanner.scanUpToString(Constants.endPlistTag)
        } else {
            // Fallback on earlier versions
        }

    }
}
