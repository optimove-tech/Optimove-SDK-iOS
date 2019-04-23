@objc public final class OptiLoggerStreamsContainer: NSObject {

    static var outputStreams: [ObjectIdentifier: OptiLoggerOutputStream] = [:]

    private static let logQueue = DispatchQueue(label: "com.optimove.sdk.log")

    public static func log(level:LogLevel,
                           fileName: String?,
                           methodName: String?,
                           logModule:String?,
                           _ message: String)
    {
        logQueue.async {
            outputStreams.values.forEach {
                if $0.isVisibleToClient {
                    if EnvVars.minLogLevelToShow <= level {
                        $0.log(level: level,
                               fileName: fileName?.components(separatedBy: "/").last ?? "",
                               methodName: methodName ?? "",
                               logModule: logModule,
                               message: message)
                    }
                } else {
                    $0.log(level: level,
                           fileName: fileName?.components(separatedBy: "/").last ?? "",
                           methodName: methodName ?? "",
                           logModule: logModule,
                           message: message)
                }
            }
        }
    }

    @objc public static func add(stream: OptiLoggerOutputStream) {
        outputStreams[ObjectIdentifier(stream)] = stream
    }
    @objc public static func remove(stream: OptiLoggerOutputStream) {
        outputStreams.removeValue(forKey: ObjectIdentifier(stream))
    }
}
