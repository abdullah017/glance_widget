import Foundation

/// A utility class for reading and writing data to App Group shared storage.
///
/// This class wraps UserDefaults with an App Group suite name, enabling
/// data sharing between the main Flutter app and the widget extension.
///
/// ## Usage
///
/// Both the main app and widget extension must:
/// 1. Have the same App Group ID in their entitlements
/// 2. Use the same `appGroupId` when initializing this class
///
/// ## Thread Safety
///
/// UserDefaults is thread-safe for reading and writing individual values.
/// This class adds `synchronize()` calls to ensure immediate persistence
/// for widget data sharing.
public class AppGroupStorage {
    private let userDefaults: UserDefaults?

    /// Initializes storage with the specified App Group ID
    ///
    /// - Parameter appGroupId: The App Group identifier (e.g., "group.com.example.app")
    public init(appGroupId: String) {
        self.userDefaults = UserDefaults(suiteName: appGroupId)
        if userDefaults == nil {
            print("GlanceWidget: Warning - Failed to initialize UserDefaults with suite: \(appGroupId)")
            print("GlanceWidget: Ensure App Group is configured in both app and widget extension entitlements")
        }
    }

    // MARK: - Save Methods

    /// Saves a dictionary to storage
    public func save(_ dictionary: [String: Any], forKey key: String) {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            userDefaults?.set(data, forKey: key)
            userDefaults?.synchronize() // Force immediate write for widget access
        } catch {
            print("GlanceWidget: Failed to save dictionary for key '\(key)': \(error)")
        }
    }

    /// Saves a string array to storage
    public func save(_ array: [String], forKey key: String) {
        do {
            let data = try JSONSerialization.data(withJSONObject: array)
            userDefaults?.set(data, forKey: key)
            userDefaults?.synchronize()
        } catch {
            print("GlanceWidget: Failed to save array for key '\(key)': \(error)")
        }
    }

    /// Saves a string to storage
    public func save(_ string: String, forKey key: String) {
        userDefaults?.set(string, forKey: key)
        userDefaults?.synchronize()
    }

    /// Saves a boolean to storage
    public func save(_ bool: Bool, forKey key: String) {
        userDefaults?.set(bool, forKey: key)
        userDefaults?.synchronize()
    }

    /// Saves an integer to storage
    public func save(_ int: Int, forKey key: String) {
        userDefaults?.set(int, forKey: key)
        userDefaults?.synchronize()
    }

    /// Saves a double to storage
    public func save(_ double: Double, forKey key: String) {
        userDefaults?.set(double, forKey: key)
        userDefaults?.synchronize()
    }

    // MARK: - Load Methods

    /// Loads a dictionary from storage
    public func loadDictionary(forKey key: String) -> [String: Any]? {
        guard let data = userDefaults?.data(forKey: key) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("GlanceWidget: Failed to load dictionary for key '\(key)': \(error)")
            return nil
        }
    }

    /// Loads a string array from storage
    public func loadArray(forKey key: String) -> [String]? {
        guard let data = userDefaults?.data(forKey: key) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data) as? [String]
        } catch {
            print("GlanceWidget: Failed to load array for key '\(key)': \(error)")
            return nil
        }
    }

    /// Loads a string from storage
    public func loadString(forKey key: String) -> String? {
        return userDefaults?.string(forKey: key)
    }

    /// Loads a boolean from storage
    public func loadBool(forKey key: String) -> Bool {
        return userDefaults?.bool(forKey: key) ?? false
    }

    /// Loads an integer from storage
    public func loadInt(forKey key: String) -> Int {
        return userDefaults?.integer(forKey: key) ?? 0
    }

    /// Loads a double from storage
    public func loadDouble(forKey key: String) -> Double {
        return userDefaults?.double(forKey: key) ?? 0.0
    }

    /// Loads raw data from storage
    public func loadData(forKey key: String) -> Data? {
        return userDefaults?.data(forKey: key)
    }

    // MARK: - Delete Methods

    /// Removes a value from storage
    public func remove(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
        userDefaults?.synchronize()
    }

    /// Removes all values with the given key prefix
    public func removeAll(withPrefix prefix: String) {
        guard let defaults = userDefaults else { return }
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }

    // MARK: - Utility Methods

    /// Returns all keys in storage
    public func allKeys() -> [String] {
        return userDefaults?.dictionaryRepresentation().keys.map { $0 } ?? []
    }

    /// Returns all keys with the given prefix
    public func keys(withPrefix prefix: String) -> [String] {
        return allKeys().filter { $0.hasPrefix(prefix) }
    }

    /// Checks if a key exists in storage
    public func exists(forKey key: String) -> Bool {
        return userDefaults?.object(forKey: key) != nil
    }
}
