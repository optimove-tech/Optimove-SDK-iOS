//
//  Extensions.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

extension String {
    func contains(_ find: String) -> Bool {
        return self.range(of: find) != nil
    }

    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }

    func setAsMongoKey() -> String {
        return self.replacingOccurrences(of: ".", with: "_")
    }
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func splitedBy(length: Int) -> [String] {
        var result = [String]()
        for i in stride(from: 0, to: self.count, by: length) {
            let endIndex = self.index(self.endIndex, offsetBy: -i)
            let startIndex = self.index(endIndex, offsetBy: -length, limitedBy: self.startIndex) ?? self.startIndex
            result.append(String(self[startIndex..<endIndex]))
        }
        return result.reversed()
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self,
                                             resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else {
            return nil
        }

        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

extension Notification.Name {
    public static let internetStatusChanged = Notification.Name.init("internetStatusChanged")
}

extension ProcessInfo {
    var operatingSystemVersionOnlyString: String {
        get {
            return "\(self.operatingSystemVersion.majorVersion).\(self.operatingSystemVersion.minorVersion).\(self.operatingSystemVersion.patchVersion)"
        }
    }
}
