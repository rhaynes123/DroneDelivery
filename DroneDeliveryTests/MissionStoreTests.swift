import Testing
import Foundation
@testable import DroneDelivery

@Suite struct MissionStoreTests {
    @Test func loadsThreeMissions() {
        let store = MissionStore(defaults: Self.isolatedDefaults())
        #expect(store.all.count == 3)
    }

    @Test func firstMissionIsUnlockedAtStart() {
        let store = MissionStore(defaults: Self.isolatedDefaults())
        #expect(store.unlocked.contains("m01_calm_pizza"))
        #expect(!store.unlocked.contains("m02_crosswind_grocery"))
    }

    @Test func completingMissionUnlocksNext() {
        let store = MissionStore(defaults: Self.isolatedDefaults())
        store.complete(id: "m01_calm_pizza", score: 1000)
        #expect(store.unlocked.contains("m02_crosswind_grocery"))
    }

    @Test func unlockAfterRefsAreValid() {
        let store = MissionStore(defaults: Self.isolatedDefaults())
        let ids = Set(store.all.map(\.id))
        for m in store.all {
            if let parent = m.unlockAfter {
                #expect(ids.contains(parent), "Mission \(m.id) references unknown parent \(parent)")
            }
        }
    }

    private static func isolatedDefaults() -> UserDefaults {
        let name = "tests.missionstore.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }
}
