import Foundation
import OSLog

/// Small cross-process preferences stored atomically inside Tickday's App Group.
/// This avoids CFPreferences suite-domain warnings while preserving shared storage.
enum SharedPreferences {
    private static let logger = Logger(
        subsystem: AppConstants.appBundleIdentifier,
        category: "SharedPreferences"
    )

    static func string(forKey key: String) -> String? {
        do {
            let data = try Data(contentsOf: valueURL(forKey: key))
            return String(data: data, encoding: .utf8)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        } catch {
            logger.error("Could not read shared preference: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func set(_ value: String?, forKey key: String) throws {
        let fileManager = FileManager.default
        let directory = try preferencesDirectory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: filename(forKey: key))

        guard let value else {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            return
        }

        try Data(value.utf8).write(to: url, options: .atomic)
    }

    static func store(_ value: String?, forKey key: String) {
        do {
            try set(value, forKey: key)
        } catch {
            logger.error("Could not write shared preference: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func valueURL(forKey key: String) throws -> URL {
        try preferencesDirectory().appending(path: filename(forKey: key))
    }

    private static func preferencesDirectory() throws -> URL {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            throw PersistenceError.appGroupUnavailable(AppConstants.appGroupIdentifier)
        }
        return groupURL.appending(path: AppConstants.sharedPreferencesDirectoryName, directoryHint: .isDirectory)
    }

    private static func filename(forKey key: String) -> String {
        let safeKey = key.map { character in
            character.isLetter || character.isNumber ? character : "_"
        }
        return String(safeKey) + ".value"
    }
}
