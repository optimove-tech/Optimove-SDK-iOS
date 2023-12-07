//  Copyright © 2019 Optimove. All rights reserved.

public enum Logger {
    public static func log(
        level: LogLevelCore,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line _: UInt = #line,
        isRemote: Bool = true
    ) {
        MultiplexLoggerStream.log(
            level: level,
            fileName: file,
            methodName: function,
            logModule: nil,
            message(),
            isRemote: isRemote
        )
    }

    public static func debug(_ message: @autoclosure () -> String,
                             file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .debug, message(), file: file, function: function, line: line)
    }

    public static func info(_ message: @autoclosure () -> String,
                            file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .info, message(), file: file, function: function, line: line)
    }

    public static func warn(_ message: @autoclosure () -> String,
                            file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .warn, message(), file: file, function: function, line: line)
    }

    public static func error(_ message: @autoclosure () -> String,
                             file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .error, message(), file: file, function: function, line: line)
    }

    public static func fatal(_ message: @autoclosure () -> String,
                             file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .fatal, message(), file: file, function: function, line: line)
    }

    public static func buisnessLogicError(_ message: @autoclosure () -> String,
                                          file: String = #file, function: String = #function, line: UInt = #line)
    {
        log(level: .fatal, message(), file: file, function: function, line: line, isRemote: false)
    }
}
