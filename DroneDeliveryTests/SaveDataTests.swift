import Testing
import Foundation
@testable import DroneDelivery

@Suite struct SaveDataTests {
    @Test func roundTripsThroughDefaults() throws {
        let original = SaveData(
            completedMissionIDs: ["m01"],
            bestScore: ["m01": 1200],
            settings: Settings(gyroEnabled: false, useImperialUnits: true)
        )
        // Use an isolated suite so the test doesn't leak.
        let suite = UserDefaults(suiteName: "tests.savedata")!
        suite.removePersistentDomain(forName: "tests.savedata")
        SaveStore.save(original, into: suite)
        let loaded = SaveStore.load(from: suite)
        #expect(loaded.completedMissionIDs == ["m01"])
        #expect(loaded.bestScore["m01"] == 1200)
        #expect(loaded.settings.useImperialUnits == true)
    }
}
