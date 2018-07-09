

import Foundation

class OptimoveFileManager
{
    static let appSupportDirectory : URL = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                    in: .userDomainMask)[0]
    static let optimoveSDKDirectory: URL = appSupportDirectory.appendingPathComponent("OptimoveSDK")
    
    static func save(data:Data, toFileName fileName: String)
    {
        do
        {
            try FileManager.default.createDirectory(at: OptimoveFileManager.optimoveSDKDirectory, withIntermediateDirectories: true)
            let filePath = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent(fileName).path
            let success = FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
            addSkipBackupAttributeToItemAtURL(filePath: filePath)
            OptiLogger.debug("Storing status of \(fileName) is \(success.description)\n location:\(OptimoveFileManager.optimoveSDKDirectory.path)")
        }
        catch
        {
            OptiLogger.debug("❌ Storing process of \(fileName) failed\n")
            return
        }
    }

    static func isExist(file fileName:String) -> Bool
    {
        let fileUrl = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }
    static func load(file fileName: String) -> Data?
    {
        let fileUrl = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent(fileName)
        do {
            let contents = try Data.init(contentsOf: fileUrl)
            return contents
        } catch {
            OptiLogger.error("contents could not be loaded from \(fileName)")
            return nil
        }
    }
    
    static func delete(file fileName: String)
    {
        let fileUrl = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
                OptiLogger.debug("Delete file \(fileName)")
            } catch {
                OptiLogger.debug("Could not delete file \(fileName)")
            }
        }
    }
    
    private static func addSkipBackupAttributeToItemAtURL(filePath:String)
    {
        let url:NSURL = NSURL(fileURLWithPath: filePath)
        do {
            try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch let error as NSError {
            print("Error excluding \(String(describing: url.lastPathComponent)) from backup \(error)");
        }
    }
}
