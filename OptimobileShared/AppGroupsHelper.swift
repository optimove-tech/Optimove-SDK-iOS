//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct AppGroupConfig {
    public static var suffix : String = ".optimove"
}

internal class AppGroupsHelper {

    internal static func isKumulosAppGroupDefined() -> Bool {
        let containerUrl = getSharedContainerPath()
        
        return containerUrl != nil
    }
    
    internal static func getSharedContainerPath() -> URL? {
       return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: getKumulosGroupName())
    }
    
    internal static func getKumulosGroupName() -> String {
        var targetBundle = Bundle.main
        if targetBundle.bundleURL.pathExtension == "appex" {
            let url = targetBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let mainBundle = Bundle(url: url) {
                targetBundle = mainBundle
            }
            else{
                print("AppGroupsHelper: Error, could not obtain main bundle from extension!")
            }
        }
       
        return "group.\(targetBundle.bundleIdentifier!)\(AppGroupConfig.suffix)"
    }
}


