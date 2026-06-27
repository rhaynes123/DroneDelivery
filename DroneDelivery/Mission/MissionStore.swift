import Foundation
import Observation

@Observable
public final class MissionStore {
    public private(set) var all: [Mission] = []
    public private(set) var zones: [String: AirspaceZone] = [:]
    public private(set) var completed: Set<String>
    public private(set) var unlocked: Set<String>

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let save = SaveStore.load(from: defaults)
        let completedIDs = save.completedMissionIDs
        self.completed = completedIDs

        let missions = Self.loadBundled([Mission].self, named: "Missions")
        self.all = missions
        let zoneList: [AirspaceZone] = Self.loadBundled([AirspaceZone].self, named: "Airspace")
        self.zones = Dictionary(uniqueKeysWithValues: zoneList.map { ($0.id, $0) })

        self.unlocked = Self.computeUnlocked(all: missions, completed: completedIDs)
    }

    public func mission(id: String) -> Mission? {
        all.first { $0.id == id }
    }

    public func complete(id: String, score: Int) {
        completed.insert(id)
        var save = SaveStore.load(from: defaults)
        save.completedMissionIDs = completed
        save.bestScore[id] = max(save.bestScore[id] ?? 0, score)
        SaveStore.save(save, into: defaults)
        unlocked = Self.computeUnlocked(all: all, completed: completed)
    }

    private static func computeUnlocked(all: [Mission], completed: Set<String>) -> Set<String> {
        var out: Set<String> = []
        for m in all {
            if m.unlockAfter == nil || completed.contains(m.unlockAfter!) {
                out.insert(m.id)
            }
        }
        return out
    }

    private static func loadBundled<T: Decodable>(_ type: T.Type, named name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing bundled resource: \(name).json")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Decode \(name).json failed: \(error)")
        }
    }
}
