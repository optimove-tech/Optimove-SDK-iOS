//  Copyright © 2019 Optimove. All rights reserved.

public final class Logger {

    public static func log(
        level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        MultiplexLoggerStream.log(
            level: level,
            fileName: file,
            methodName: function,
            logModule: nil,
            message()
        )
    }

    public static func debug(_ message: @autoclosure () -> String,
                      file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .debug, message(), file: file, function: function, line: line)
    }

    public static func info(_ message: @autoclosure () -> String,
                     file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .info, message(), file: file, function: function, line: line)
    }

    public static func warn(_ message: @autoclosure () -> String,
                     file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .warn, message(), file: file, function: function, line: line)
    }

    public static func error(_ message: @autoclosure () -> String,
                      file: String = #file, function: String = #function, line: UInt = #line) {
        log(level: .error, message(), file: file, function: function, line: line)
    }

}
