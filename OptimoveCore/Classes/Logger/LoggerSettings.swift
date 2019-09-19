//  Copyright © 2019 Optimove. All rights reserved.

public struct LoggerSettings {

    public static var logLevelToShow: LogLevelCore = {
        return SDK.isStaging ? LogLevelCore.info : LogLevelCore.warn
    }()

}

