@objc public final class OptiLogger:NSObject
{
    private static var outputStreams:[ObjectIdentifier:OptiLoggerOutputStream] = [:]
    private static let logQueue = DispatchQueue(label: "com.optimove.sdk.log")
    public static func debug(tag:String = "", _ message: String,_ args:[String] = [])
    {
        logQueue.async {
            outputStreams.values.forEach { $0.debug(tag: tag, message: message, args: args) }
        }
    }
    public static func info(tag:String , _ message: String,_ args:[String] = [])
    {
        logQueue.async {
            outputStreams.values.forEach { $0.info(tag: tag, message: message,  args: args) }
        }
    }
    public static func warning(tag:String = "" , _ message: String,_ args:[String] = [])
    {
        logQueue.async {
            outputStreams.values.forEach { $0.warning(tag: tag, message: message, args: args) }
        }
    }

    public static func error(tag:String = "" , _ message: String,_ args:[String] = [])
    {
        logQueue.async {
            outputStreams.values.forEach { $0.error(tag: tag, message: message, args: args) }
        }
    }
    public static func fatal(tag:String , _ message: String,_ args:[String] = [])
    {
        logQueue.async {
            outputStreams.values.forEach { $0.fatal(tag: tag, message: message, args: args) }
        }
    }
    
    @objc public static func add(stream:OptiLoggerOutputStream) {
        outputStreams[ObjectIdentifier(stream)] = stream
    }
    @objc public static func remove(stream:OptiLoggerOutputStream) {
        outputStreams.removeValue(forKey: ObjectIdentifier(stream))
    }
}
