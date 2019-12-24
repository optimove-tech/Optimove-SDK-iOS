//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct SdkEnvironment {

    public struct Constants {
        public struct Key {
            public static let debugEnabled = "-optimove-debug-enabled"
        }
    }

    public static let isDebugEnabled: Bool = {
        return ProcessInfo.processInfo.arguments.contains(Constants.Key.debugEnabled)
    }()

    static func getEnvironmentVariable(for key: String, defaultValue: String) -> String {
        guard let envVarValue = ProcessInfo.processInfo.environment[key], !envVarValue.isEmpty else {
            return defaultValue
        }
        return envVarValue
    }
}
