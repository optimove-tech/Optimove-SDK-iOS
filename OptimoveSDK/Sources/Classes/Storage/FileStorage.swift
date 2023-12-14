//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public protocol FileStorage {
    /// Check file if exist.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    ///
    /// - Returns: Return `true` if the requested file exist.
    func isExist(fileName: String, isTemporary: Bool) -> Bool

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: `Codable` object that will be saved.
    ///   - toFileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    func save<T: Codable>(data: T, toFileName: String, isTemporary: Bool) throws

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Raw data
    ///   - toFileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    func saveData(data: Data, toFileName: String, isTemporary: Bool) throws

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    ///
    /// - Returns: Return `Data` if file will be found, or `nil` if not.
    func loadData(fileName: String, isTemporary: Bool) throws -> Data

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    ///
    /// - Returns: Return `Codable` if file will be found, or `nil` if not.
    func load<T: Codable>(fileName: String, isTemporary: Bool) throws -> T

    /// Delete file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isTemporary: set `true` if the requested file should be saved in a temporary directory.
    ///   The file will be removed after app will be terminated. Default value is `false`.
    func delete(fileName: String, isTemporary: Bool) throws
}

extension FileStorage {
    func isExist(fileName: String) -> Bool {
        return isExist(fileName: fileName, isTemporary: false)
    }

    func save<T: Codable>(data: T, toFileName: String, isTemporary: Bool = false) throws {
        try save(data: data, toFileName: toFileName, isTemporary: isTemporary)
    }

    func saveData(data: Data, toFileName: String, isTemporary: Bool = false) throws {
        try saveData(data: data, toFileName: toFileName, isTemporary: isTemporary)
    }

    func loadData(fileName: String, isTemporary: Bool = false) throws -> Data {
        return try loadData(fileName: fileName, isTemporary: isTemporary)
    }

    func load<T: Codable>(fileName: String, isTemporary: Bool = false) throws -> T {
        return try load(fileName: fileName, isTemporary: isTemporary)
    }

    func delete(fileName: String, isTemporary: Bool = false) throws {
        try delete(fileName: fileName, isTemporary: isTemporary)
    }
}

public final class FileStorageImpl {
    enum FileStorageError: Error {
        case unableToCreateDirectory
        case unableToSaveFile
        case unableToLoadFile
        case unableToDeleteFile
    }

    private enum Constants {
        static let folderName = "OptimoveSDK"
    }

    let fileManager: FileManager
    let persistentStorageURL: URL
    let temporaryStorageURL: URL

    public init(persistentStorageURL: URL, temporaryStorageURL: URL) throws {
        fileManager = FileManager.default
        self.persistentStorageURL = persistentStorageURL
        self.temporaryStorageURL = temporaryStorageURL
    }

    private func addSkipBackupAttributeToItemAtURL(fileURL: URL) throws {
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func getDirectory(isTemporary: Bool) -> URL {
        let url = isTemporary ?
            temporaryStorageURL :
            persistentStorageURL.appendingPathComponent(Constants.folderName)
        return url
    }
}

extension FileStorageImpl: FileStorage {
    public func isExist(fileName: String, isTemporary: Bool) -> Bool {
        let url = getDirectory(isTemporary: isTemporary)
        let fileUrl = url.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    public func loadData(fileName: String, isTemporary: Bool) throws -> Data {
        let fileUrl = getDirectory(isTemporary: isTemporary).appendingPathComponent(fileName)
        do {
            let contents = try unwrap(fileManager.contents(atPath: fileUrl.path))
            Logger.debug("Load file at \(fileName)")
            return contents
        } catch {
            Logger.warn("Unable to load file \(fileName) at \(fileUrl.path). Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func load<T>(fileName: String, isTemporary: Bool) throws -> T where T: Decodable, T: Encodable {
        let data = try loadData(fileName: fileName, isTemporary: isTemporary)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save<T: Encodable>(data: T, toFileName fileName: String, isTemporary: Bool) throws {
        let data = try JSONEncoder().encode(data)
        try saveData(data: data, toFileName: fileName, isTemporary: isTemporary)
    }

    public func saveData(data: Data, toFileName fileName: String, isTemporary: Bool) throws {
        do {
            let url = getDirectory(isTemporary: isTemporary)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let fileURL = url.appendingPathComponent(fileName)
            let success = fileManager.createFile(
                atPath: fileURL.path, contents: data, attributes: nil
            )
            try addSkipBackupAttributeToItemAtURL(fileURL: fileURL)
            Logger.debug("File stored at \(fileURL.path) successfull \(success.description).")
        } catch {
            Logger.error("Unable to store file \(fileName) failed. Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func delete(fileName: String, isTemporary: Bool) throws {
        do {
            let fileUrl = getDirectory(isTemporary: isTemporary).appendingPathComponent(fileName)
            try fileManager.removeItem(at: fileUrl)
            Logger.debug("File deleted at \(fileUrl.absoluteString).")
        } catch {
            Logger.error("Unable to delete file \(fileName). Reason: \(error.localizedDescription)")
            throw error
        }
    }
}
