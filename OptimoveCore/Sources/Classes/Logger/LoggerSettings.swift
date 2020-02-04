//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct LoggerSettings {

    public static let logLevelToShow: LogLevelCore = {
        return SdkEnvironment.isDebugEnabled ? LogLevelCore.debug : LogLevelCore.warn
    }()
}
