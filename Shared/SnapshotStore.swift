import Foundation

/// App Group storage for the widget. Letters never pass through this store.
enum SnapshotStore {
    static func write(_ snapshot: JourneySnapshot) {
        guard let defaults = UserDefaults(suiteName: AppIdentity.appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: JourneySnapshot.storageKey)
    }

    static func read() -> JourneySnapshot? {
        guard let defaults = UserDefaults(suiteName: AppIdentity.appGroupID),
              let data = defaults.data(forKey: JourneySnapshot.storageKey)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(JourneySnapshot.self, from: data)
    }

    static func clear() {
        UserDefaults(suiteName: AppIdentity.appGroupID)?
            .removeObject(forKey: JourneySnapshot.storageKey)
    }
}
