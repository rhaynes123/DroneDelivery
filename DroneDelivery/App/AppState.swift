import Foundation
import Observation

@Observable
public final class AppState {
    public var phase: GamePhase = .menu
    public var currentMission: Mission?
    public var currentAirspaceID: String?
    public var batteryPercent: Double = 100
    public var altitudeAGLFt: Float = 0
    public var paused: Bool = false
    public var failureReason: String?
    public var score: Int = 0

    public init() {}

    public func reset(for mission: Mission) {
        self.currentMission = mission
        self.currentAirspaceID = nil
        self.batteryPercent = 100
        self.altitudeAGLFt = 0
        self.paused = false
        self.failureReason = nil
        self.score = 0
        self.phase = .briefing
    }
}
