//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol FileStorage {

    /// Check file if exist.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    /// - Returns: Return `true` if the requested file exist.
    func isExist(fileName: String, isGroupContainer: Bool) -> Bool

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: `Codable` object that will be saved.
    ///   - toFileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    func save<T: Codable>(data: T, toFileName: String, isGroupContainer: Bool) throws

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Raw data
    ///   - toFileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    func saveData(data: Data, toFileName: String, isGroupContainer: Bool) throws

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    /// - Returns: Return `Data` if file will be found, or `nil` if not.
    func loadData(fileName: String, isGroupContainer: Bool) throws -> Data

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    /// - Returns: Return `Codable` if file will be found, or `nil` if not.
    func load<T: Codable>(fileName: String, isGroupContainer: Bool) throws -> T

    /// Delete file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    func delete(fileName: String, isGroupContainer: Bool) throws

}

public final class FileStorageImpl {

    private struct Constants {
        static let folderName = "OptimoveSDK"
    }

    private let fileManager: FileManager
    private let groupedDirectoryURL: URL
    private let sharedDirectoryURL: URL

    public init(bundleIdentifier: String,
                fileManager: FileManager) throws {
        self.fileManager = fileManager

        groupedDirectoryURL = try fileManager.groupContainer(tenantBundleIdentifier: bundleIdentifier)
        sharedDirectoryURL = try unwrap(fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
    }

    private func addSkipBackupAttributeToItemAtURL(fileURL: URL) throws {
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func getDirectory(isGroupContainer: Bool) -> URL {
        let url = isGroupContainer ? groupedDirectoryURL : sharedDirectoryURL
        return url.appendingPathComponent(Constants.folderName)
    }
}

extension FileStorageImpl: FileStorage {

    public func isExist(fileName: String, isGroupContainer: Bool) -> Bool {
        let url = getDirectory(isGroupContainer: isGroupContainer)
        let fileUrl = url.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    public func loadData(fileName: String, isGroupContainer: Bool) throws -> Data {
        let fileUrl = getDirectory(isGroupContainer: isGroupContainer).appendingPathComponent(fileName)
        do {
            let contents = try unwrap(fileManager.contents(atPath: fileUrl.path))
            Logger.debug("Load file at \(fileName)")
            return contents
        } catch {
            Logger.error("Unable to load file \(fileName) at \(fileUrl.path). Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func load<T: Codable>(fileName: String, isGroupContainer: Bool) throws -> T {
        let data = try loadData(fileName: fileName, isGroupContainer: isGroupContainer)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save<T: Encodable>(
        data: T,
        toFileName fileName: String,
        isGroupContainer: Bool = false) throws {
        let data = try JSONEncoder().encode(data)
        try saveData(data: data, toFileName: fileName, isGroupContainer: isGroupContainer)
    }

    public func saveData(
        data: Data,
        toFileName fileName: String,
        isGroupContainer: Bool = false) throws {
        do {
            let url = getDirectory(isGroupContainer: isGroupContainer)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let fileURL = url.appendingPathComponent(fileName)
            let success = fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
            try addSkipBackupAttributeToItemAtURL(fileURL: fileURL)
            Logger.debug("File stored at \(fileName) successfull \(success.description).")
        } catch {
            Logger.error("Unable to store file \(fileName) failed. Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func delete(fileName: String, isGroupContainer: Bool) throws {
        do {
            let fileUrl = getDirectory(isGroupContainer: isGroupContainer).appendingPathComponent(fileName)
            try fileManager.removeItem(at: fileUrl)
            Logger.debug("File deleted at \(fileUrl.absoluteString).")
        } catch {
            Logger.error("Unable to delete file \(fileName). Reason: \(error.localizedDescription)")
            throw error
        }
    }

}
