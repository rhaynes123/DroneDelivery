import Foundation

public struct Settings: Codable, Sendable {
    public var gyroEnabled: Bool
    public var useImperialUnits: Bool

    public static let `default` = Settings(gyroEnabled: false, useImperialUnits: true)
}

public struct SaveData: Codable, Sendable {
    public var completedMissionIDs: Set<String>
    public var bestScore: [String: Int]
    public var settings: Settings

    public static let `default` = SaveData(
        completedMissionIDs: [],
        bestScore: [:],
        settings: .default
    )
}

public enum SaveStore {
    private static let key = "DroneDelivery.save.v1"

    public static func load(from defaults: UserDefaults = .standard) -> SaveData {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SaveData.self, from: data)
        else { return .default }
        return decoded
    }

    public static func save(_ snapshot: SaveData, into defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }
}
