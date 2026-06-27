import Foundation
import simd

public enum CargoKind: String, Codable, Sendable {
    case pizza, groceries, video, clothes
}

public enum TimeOfDay: String, Codable, Sendable {
    case day, dusk, night
}

public struct Waypoint: Codable, Sendable {
    public let position: SIMD3<Float>
    public let label: String
}

public struct Conditions: Codable, Sendable {
    public let weather: WeatherSpec
    public let airspace: [String]   // refs AirspaceZone.id
    public let notams: [NOTAM]
    public let batteryWh: Double
    public let timeOfDay: TimeOfDay
}

public struct Mission: Codable, Identifiable, Sendable {
    public let id: String
    public let cargoTheme: CargoKind
    public let pickup: Waypoint
    public let dropoff: Waypoint
    public let conditions: Conditions
    public let unlockAfter: String?
}
