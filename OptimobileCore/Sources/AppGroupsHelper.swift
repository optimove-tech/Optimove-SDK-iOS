//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public enum AppGroupConfig {
    public static var suffix: String = ".optimove"
}

public enum AppGroupsHelper {
    public static func isKumulosAppGroupDefined() -> Bool {
        let containerUrl = getSharedContainerPath()

        return containerUrl != nil
    }

    public static func getSharedContainerPath() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: getKumulosGroupName())
    }

    static func getKumulosGroupName() -> String {
        var targetBundle = Bundle.main
        if targetBundle.bundleURL.pathExtension == "appex" {
            let url = targetBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let mainBundle = Bundle(url: url) {
                targetBundle = mainBundle
            } else {
                print("AppGroupsHelper: Error, could not obtain main bundle from extension!")
            }
        }

        return "group.\(targetBundle.bundleIdentifier!)\(AppGroupConfig.suffix)"
    }
}
