import Foundation
import SwiftData
import OSLog

enum PersistenceError: LocalizedError {
    case appGroupUnavailable(String)
    case storeInitializationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable(let identifier): "App Group \(identifier) is unavailable. Check signing and entitlements."
        case .storeInitializationFailed(let error): "The Tickday database could not be opened: \(error.localizedDescription)"
        }
    }
}

enum SharedModelContainer {
    static let schema = Schema([CountdownEvent.self, TaskDefinition.self, TaskCompletion.self])
    private static let logger = Logger(subsystem: AppConstants.appBundleIdentifier, category: "Persistence")

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        do {
            if inMemory {
                return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            }
            guard let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
            ) else {
                throw PersistenceError.appGroupUnavailable(AppConstants.appGroupIdentifier)
            }
            let storeURL = groupURL.appending(path: AppConstants.sharedStoreName)
            let configuration = ModelConfiguration("TickdayShared", schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch let error as PersistenceError {
            logger.error("Shared container unavailable: \(error.localizedDescription, privacy: .public)")
            throw error
        } catch {
            logger.fault("Store initialization failed: \(error.localizedDescription, privacy: .public)")
            throw PersistenceError.storeInitializationFailed(error)
        }
    }
}
