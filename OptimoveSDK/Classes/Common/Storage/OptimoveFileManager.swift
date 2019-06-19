import Foundation

class OptimoveFileManager {
    static func getOptimoveSDKDirectory(isForSharedContainer: Bool) -> URL {
        let fileManager = FileManager.default
        var url: URL!
        if isForSharedContainer {
            url = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier!).optimove"
            )
        } else {
            url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
        return url.appendingPathComponent("OptimoveSDK")
    }

    static func save(data: Data, toFileName fileName: String, isForSharedContainer: Bool = false) {
        do {
            let fileManager = FileManager.default
            let url = getOptimoveSDKDirectory(isForSharedContainer: isForSharedContainer)

            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let filePath = url.appendingPathComponent(fileName).path
            let success = fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
            addSkipBackupAttributeToItemAtURL(filePath: filePath)
            OptiLoggerMessages.logStoringFileStatus(
                name: fileName,
                successStatus: success.description,
                fileLocation: url.path
            )
        } catch {
            OptiLoggerMessages.logStringFailureStatus(name: fileName)
            return
        }
    }

    static func isExist(file fileName: String, isInSharedContainer: Bool) -> Bool {
        let url = getOptimoveSDKDirectory(isForSharedContainer: isInSharedContainer)
        let fileUrl = url.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }

    static func load(file fileName: String, isInSharedContainer: Bool) -> Data? {
        let fileUrl = getOptimoveSDKDirectory(isForSharedContainer: isInSharedContainer).appendingPathComponent(
            fileName
        )
        do {
            let contents = try Data.init(contentsOf: fileUrl)
            OptiLoggerMessages.logLoadFile(fileUrl: fileUrl.path)
            return contents
        } catch {
            OptiLoggerMessages.logLoadFileFailure(name: fileName)
            return nil
        }
    }

    static func delete(file fileName: String, isInSharedContainer: Bool) {
        let fileUrl = getOptimoveSDKDirectory(isForSharedContainer: isInSharedContainer).appendingPathComponent(
            fileName
        )
        if FileManager.default.fileExists(atPath: fileUrl.absoluteString) {
            do {
                try FileManager.default.removeItem(at: fileUrl)
                OptiLoggerMessages.logDeleteFile(name: fileName)
            } catch {
                OptiLoggerMessages.logFileDeletionFailure(name: fileName)
            }
        }
    }

    private static func addSkipBackupAttributeToItemAtURL(filePath: String) {
        let url: NSURL = NSURL(fileURLWithPath: filePath)
        do {
            try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch let error as NSError {
            print("Error excluding \(String(describing: url.lastPathComponent)) from backup \(error)")
        }
    }
}
