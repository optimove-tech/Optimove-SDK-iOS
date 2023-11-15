//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct MobileProvision: Decodable {
    let entitlements: Entitlements
    let provisionsAllDevices: Bool?

    private enum CodingKeys: String, CodingKey {
        case entitlements = "Entitlements"
        case provisionsAllDevices = "ProvisionsAllDevices"
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
            let apsEnvironment: Environment = try container.decodeIfPresent(Environment.self, forKey: .apsEnvironment) ?? .disabled
            self.init(apsEnvironment: apsEnvironment)
        }
    }
}

extension MobileProvision {
    enum UIApplicationReleaseMode: Int {
        case unknown,
             releaseDev,
             releaseAdHoc,
             releaseWildcard,
             releaseAppStore,
             releaseSim,
             releaseEnterprise
    }

    private struct PlistTags {
        static let start = "<plist"
        static let end = "</plist>"
    }

    static func read() throws -> MobileProvision {
        let profilePath: String = try unwrap(Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"))
        return try read(from: profilePath)
    }

    static func read(from profilePath: String) throws -> MobileProvision {
        let profile = try String(contentsOfFile: profilePath, encoding: String.Encoding.isoLatin1)
        let plistString: String = try unwrap(convertPlistDataToString(profile))
        let plistData: Data = try unwrap(plistString.appending(PlistTags.end).data(using: .isoLatin1))
        let decoder = PropertyListDecoder()
        return try decoder.decode(MobileProvision.self, from: plistData)
    }

    private static func convertPlistDataToString(_ string: String) throws -> String {
        let scanner = Scanner(string: string)
        let startError = GuardError.custom("Not found plist tag \(PlistTags.start), in '\(string)'")
        let endError = GuardError.custom("Not found plist tag \(PlistTags.end), in '\(string)'")
        _ = try unwrap(scanner.scanUpTo(PlistTags.start, into: nil), error: startError)
        var extractedPlist: NSString?
        guard scanner.scanUpTo(PlistTags.end, into: &extractedPlist) != false else {
            throw endError
        }
        return try String(unwrap(extractedPlist))
    }

    static func releaseMode() -> UIApplicationReleaseMode {
        guard let mobileProvision = try? MobileProvision.read() else { return .unknown }

        if mobileProvision.provisionsAllDevices ?? false {
            return .releaseEnterprise
        }

        switch mobileProvision.entitlements.apsEnvironment {
        case .disabled:
            return .unknown
        case .development:
            return .releaseDev
        case .production:
            return .releaseAppStore
        }
    }
}
