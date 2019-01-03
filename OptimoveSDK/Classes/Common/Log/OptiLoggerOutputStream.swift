@objc public protocol OptiLoggerOutputStream:AnyObject
{
    func debug(tag: String, message: String, args: [String])
    func info(tag: String, message: String, args: [String])
    func warning(tag: String, message: String, args: [String])
    func error(tag: String, message: String, args: [String])
    func fatal(tag: String, message: String, args: [String])
}
