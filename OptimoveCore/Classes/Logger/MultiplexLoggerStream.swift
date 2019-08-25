//  Copyright © 2019 Optimove. All rights reserved.

public final class MultiplexLoggerStream {

    private struct Constants {
        static let delimiter = "/"
        static let placeholder = ""
    }

    static var outputStreams: [ObjectIdentifier: LoggerStream] = [:]

    private static let logQueue = DispatchQueue(label: "com.optimove.sdk.log")

    public static func log(
        level: LogLevelCore,
        fileName: String?,
        methodName: String?,
        logModule: String?,
        _ message: String
    ) {
        logQueue.async {
            let file = fileName?.components(separatedBy: Constants.delimiter).last ?? Constants.placeholder
            let function = methodName ?? Constants.placeholder
            outputStreams.values.forEach { outputStream in
                switch outputStream.policy {
                case .userDefined:
                    guard LoggerSettings.logLevelToShow <= level else { return }
                    fallthrough
                case .all:
                    outputStream.log(
                        level: level,
                        fileName: file,
                        methodName: function,
                        logModule: logModule,
                        message: message
                    )
                }
            }
        }
    }

    public static func add(stream: LoggerStream) {
        outputStreams[ObjectIdentifier(stream)] = stream
    }

    public static func remove(stream: LoggerStream) {
        outputStreams.removeValue(forKey: ObjectIdentifier(stream))
    }

    public static func mutateStreams(mutator: (MutableLoggerStream) -> Void) {
        outputStreams
            .values
            .compactMap { $0 as? MutableLoggerStream }
            .forEach (mutator)
    }
}
