//  Copyright © 2024 Optimove. All rights reserved.

import Foundation

public enum ApplicationInfo {
    public static let bundleIdentifier = Bundle.main.bundleIdentifier!
    public static let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    public static let build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
}
