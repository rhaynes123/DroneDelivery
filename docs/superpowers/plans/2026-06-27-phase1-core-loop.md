# DroneDelivery Phase 1 — Core Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a runnable iPhone/iPad build with three Part-107-themed delivery missions on one programmatic city map, with full briefing → flying → debrief loop, battery/altitude/airspace/collision enforcement, and wind as the only weather effect that mutates flight.

**Architecture:** SwiftUI app + one `RealityView` hosting a drone Entity built from custom Components. A single `KinematicSystem` mutates Components each frame; SwiftUI views read mirror values from an `@Observable` `AppState`. Missions are JSON data, progress is one `Codable` struct in `UserDefaults`.

**Tech Stack:** Swift 6 (strict concurrency), SwiftUI, RealityKit, Swift Testing (`import Testing`). No third-party dependencies. No GameplayKit, no SwiftData (those are Phase 2 and 3).

## Global Constraints

- iOS / iPadOS 18+ deployment target. Xcode 16+.
- Swift 6 strict concurrency on. No `@unchecked Sendable` without a one-line justification comment.
- **No SPM dependencies.** Apple frameworks only.
- **No `PhysicsBody` on the drone.** Custom kinematic only. RealityKit `CollisionComponent` is allowed for collision detection events without physics simulation.
- **No GameplayKit, no SwiftData, no MapKit.** Phase 2/3 / out of scope.
- **No `// TODO:` comments.** Use `// ponytail:` to mark deliberate shortcuts with their upgrade path. Use `// CFR §<n>` to cite any regulation a constant encodes.
- All folders under `DroneDelivery/` group by domain (see `CLAUDE.md` layout). Files over ~150 lines are a signal to split.
- Run `/simplify` (or `/code-review --fix`) on the diff before declaring any task done.
- Update `CHANGELOG.md` (`## [Unreleased]`) in the same commit as any task change.
- Cite the rule in code for any encoded regulation. Source: `REFERENCES.md`.

---

## Task 1: Xcode project bootstrap

**Goal:** A clean Xcode project committed to git, with the empty domain folder structure ready.

**Files:**
- Create: `DroneDelivery.xcodeproj/` (via Xcode wizard)
- Create: `DroneDelivery/DroneDeliveryApp.swift` (Xcode generates; we trim)
- Delete: `DroneDelivery/ContentView.swift` (Xcode generates a default we don't want)
- Create: empty folder structure under `DroneDelivery/` matching the spec
- Modify: `.gitignore` if Xcode adds anything not already covered

**Interfaces produced:** none yet — this task is scaffolding.

- [ ] **Step 1: Create the Xcode project**

In Xcode: **File → New → Project → iOS → App**. Settings:

| Field | Value |
|---|---|
| Product Name | `DroneDelivery` |
| Team | your personal team |
| Organization Identifier | `com.rhaynes123` (or your preference — used as bundle prefix) |
| Interface | SwiftUI |
| Language | Swift |
| Include Tests | **Yes** |
| Storage | None |

Save into `/Users/richardhaynes/Developer/Projects/Swift/DroneDelivery/` — **uncheck "Create Git repository"** (we already have one).

- [ ] **Step 2: Verify the project builds**

In Xcode, press ⌘B. Expected: build succeeds, no errors.

- [ ] **Step 3: Set deployment target to iOS 18 and Swift 6**

Project → DroneDelivery target → General → Minimum Deployments → iOS 18.0.
Project → DroneDelivery target → Build Settings → Swift Language Version → **Swift 6**.
Project → DroneDelivery target → Build Settings → Strict Concurrency Checking → **Complete**.

⌘B again to confirm still builds.

- [ ] **Step 4: Delete the default ContentView, trim DroneDeliveryApp**

Delete `DroneDelivery/ContentView.swift` (move to trash).

Replace `DroneDelivery/DroneDeliveryApp.swift` with the minimal entry — RootView will come in Task 13, so for now use a placeholder:

```swift
import SwiftUI

@main
struct DroneDeliveryApp: App {
    var body: some Scene {
        WindowGroup {
            Text("DroneDelivery")
        }
    }
}
```

⌘B to confirm builds.

- [ ] **Step 5: Create the empty domain folders**

In Xcode's Project Navigator, right-click `DroneDelivery` → New Group (without folder). Create groups: `App`, `Scenes`, `Drone`, `Flight`, `Mission`, `Airspace`, `Weather`, `UI`, `Persistence`.

Then **move `DroneDeliveryApp.swift` into `App/`**.

- [ ] **Step 6: Run on simulator**

⌘R, select an iPhone 15 simulator. Expected: simulator boots, shows "DroneDelivery" text on white background. Stop the run.

- [ ] **Step 7: Update CHANGELOG and commit**

Add to `CHANGELOG.md` under `## [Unreleased]` → `### Added`:

```
- Xcode project scaffold: iOS 18+, Swift 6 strict concurrency, empty domain folders.
```

```bash
git add -A
git commit -m "Bootstrap Xcode project (iOS 18, Swift 6 strict concurrency)"
```

---

## Task 2: Domain model types

**Goal:** All plain `Codable` value types the game needs, plus one focused test for the most error-prone piece (polygon containment).

**Files:**
- Create: `DroneDelivery/Mission/MissionTypes.swift`
- Create: `DroneDelivery/Airspace/AirspaceTypes.swift`
- Create: `DroneDelivery/Weather/Weather.swift`
- Create: `DroneDelivery/App/GamePhase.swift`
- Create: `DroneDeliveryTests/AirspaceTypesTests.swift`

**Interfaces produced:**
- `enum CargoKind: String, Codable, Sendable { case pizza, groceries, video, clothes }`
- `enum TimeOfDay: String, Codable, Sendable { case day, dusk, night }`
- `enum AirspaceClass: String, Codable, Sendable { case b, c, d, e, g }`
- `enum GamePhase: Sendable { case menu, briefing, preflight, flying, delivering, returning, debrief }`
- `struct Waypoint: Codable, Sendable { let position: SIMD3<Float>; let label: String }`
- `struct WeatherSpec: Codable, Sendable { let windKts, windDir, visibilitySM, ceilingFtAGL, temperatureC, densityAltitudeFt: Float }`
- `struct AirspaceZone: Codable, Identifiable, Sendable { let id, polygonName: String; let `class`: AirspaceClass; let polygon: [SIMD2<Float>]; let floorAGL, ceilingAGL: Float; let requiresAuthorization: Bool; func contains(_ p: SIMD2<Float>) -> Bool }`
- `struct NOTAM: Codable, Identifiable, Sendable { let id, reason: String; let polygon: [SIMD2<Float>]; let floorAGL, ceilingAGL: Float; let start, end: Date }`
- `struct Mission: Codable, Identifiable, Sendable { let id: String; let cargoTheme: CargoKind; let pickup, dropoff: Waypoint; let conditions: Conditions; let unlockAfter: String? }`
- `struct Conditions: Codable, Sendable { let weather: WeatherSpec; let airspace: [String]; let notams: [NOTAM]; let batteryWh: Double; let timeOfDay: TimeOfDay }`

(`Conditions.airspace` is an array of `AirspaceZone.id` references — the zones themselves live in a separate `Airspace.json`. Cleaner than embedding.)

- [ ] **Step 1: Write the failing polygon-containment test**

Create `DroneDeliveryTests/AirspaceTypesTests.swift`:

```swift
import Testing
import simd
@testable import DroneDelivery

@Suite struct AirspaceTypesTests {
    @Test func zoneContainsPointInside() {
        let zone = AirspaceZone(
            id: "Z1", polygonName: "test", class: .g,
            polygon: [SIMD2(0,0), SIMD2(10,0), SIMD2(10,10), SIMD2(0,10)],
            floorAGL: 0, ceilingAGL: 400, requiresAuthorization: false
        )
        #expect(zone.contains(SIMD2(5, 5)))
    }

    @Test func zoneExcludesPointOutside() {
        let zone = AirspaceZone(
            id: "Z1", polygonName: "test", class: .g,
            polygon: [SIMD2(0,0), SIMD2(10,0), SIMD2(10,10), SIMD2(0,10)],
            floorAGL: 0, ceilingAGL: 400, requiresAuthorization: false
        )
        #expect(!zone.contains(SIMD2(15, 5)))
    }
}
```

- [ ] **Step 2: Run the test, verify it fails to compile (types don't exist yet)**

Run: ⌘U in Xcode. Expected: build fails with "cannot find 'AirspaceZone' in scope."

- [ ] **Step 3: Create `Mission/MissionTypes.swift`**

```swift
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
```

- [ ] **Step 4: Create `Weather/Weather.swift`**

```swift
import Foundation

public struct WeatherSpec: Codable, Sendable {
    public let windKts: Float
    public let windDir: Float        // degrees true
    public let visibilitySM: Float
    public let ceilingFtAGL: Float
    public let temperatureC: Float
    public let densityAltitudeFt: Float
}
```

- [ ] **Step 5: Create `Airspace/AirspaceTypes.swift`**

```swift
import Foundation
import simd

public enum AirspaceClass: String, Codable, Sendable {
    case b, c, d, e, g
}

public struct AirspaceZone: Codable, Identifiable, Sendable {
    public let id: String
    public let polygonName: String
    public let `class`: AirspaceClass
    public let polygon: [SIMD2<Float>]
    public let floorAGL: Float
    public let ceilingAGL: Float
    public let requiresAuthorization: Bool

    // Ray-casting point-in-polygon. Works for any simple polygon (no holes).
    public func contains(_ p: SIMD2<Float>) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let pi = polygon[i], pj = polygon[j]
            let intersects = ((pi.y > p.y) != (pj.y > p.y)) &&
                (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }
}

public struct NOTAM: Codable, Identifiable, Sendable {
    public let id: String
    public let reason: String
    public let polygon: [SIMD2<Float>]
    public let floorAGL: Float
    public let ceilingAGL: Float
    public let start: Date
    public let end: Date

    public func contains(_ p: SIMD2<Float>) -> Bool {
        // ponytail: shares polygon math with AirspaceZone; extract a free
        // function if a third polygon owner appears.
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let pi = polygon[i], pj = polygon[j]
            let intersects = ((pi.y > p.y) != (pj.y > p.y)) &&
                (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)
            if intersects { inside.toggle() }
            j = i
        }
        return inside
    }
}
```

- [ ] **Step 6: Create `App/GamePhase.swift`**

```swift
import Foundation

public enum GamePhase: Sendable {
    case menu, briefing, preflight, flying, delivering, returning, debrief
}
```

- [ ] **Step 7: Run the tests, verify they pass**

Run: ⌘U. Expected: both polygon tests pass.

- [ ] **Step 8: Update CHANGELOG and commit**

`CHANGELOG.md` → `## [Unreleased]` → `### Added`:

```
- Domain model types: Mission, Conditions, Waypoint, WeatherSpec, AirspaceZone (with polygon containment), NOTAM, GamePhase.
```

```bash
git add -A
git commit -m "Add domain models with polygon containment test"
```

---

## Task 3: PhysicsTuning constants

**Goal:** All calibration knobs in one file, each citing its CFR section or the physical principle it encodes.

**Files:**
- Create: `DroneDelivery/Flight/PhysicsTuning.swift`

**Interfaces produced:**
- `enum PhysicsTuning` (namespace of `static let` constants) — used by `KinematicSystem` in Task 6 and HUD in Task 12.

- [ ] **Step 1: Create `Flight/PhysicsTuning.swift`**

```swift
import Foundation

/// Centralised tuning constants. Every value is a knob — real drones, wind,
/// and batteries need calibration that a minimal model can't see.
public enum PhysicsTuning {

    // CFR § 107.51(b): max altitude 400 ft AGL unless within 400 ft of a structure.
    public static let maxAltitudeAGLFt: Float = 400

    // Arcade drone top speed in m/s (~22 kts). DJI Mavic 3 is ~21 m/s in Sport mode.
    // ponytail: per-mission limits could override this; add a per-mission cap if missions need it.
    public static let maxSpeedMS: Float = 11

    // Velocity smoothing: fraction of (target - current) applied per frame at 60 fps.
    // 0.18 ≈ ~150 ms time-to-target, feels responsive but not twitchy.
    public static let velocityLerp: Float = 0.18

    // Wind transfer: how much of the wind vector adds to drone velocity.
    // ponytail: real coupling depends on attitude + mass; 0.6 is a one-knob approximation.
    public static let windCoupling: Float = 0.6

    // Battery drain in watts.
    // 80 Wh battery on a 200 W base draw = ~24 minutes hover. Real DJI Mavic 3: ~46 min.
    // Tighter on purpose: missions need to feel battery-constrained.
    public static let baseDrainW: Double = 200
    public static let perMSDrainW: Double = 12    // additional W per m/s of speed
    public static let perKtWindFightDrainW: Double = 6  // additional W per kt of wind being fought

    // Default battery if a mission doesn't specify (used by tests / previews).
    public static let defaultBatteryWh: Double = 80

    // Conversion: 1 m = 3.28084 ft.
    public static let metresToFeet: Float = 3.28084
    public static let knotsToMS: Float = 0.514444
}
```

- [ ] **Step 2: Build to confirm no errors**

⌘B. Expected: clean build.

- [ ] **Step 3: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- PhysicsTuning constants (Flight/PhysicsTuning.swift) — all calibration knobs in one place.
```

```bash
git add -A
git commit -m "Add PhysicsTuning constants with CFR citations"
```

---

## Task 4: Persistence (SaveData + UserDefaults wrapper)

**Goal:** A `Codable` `SaveData` struct that round-trips through `UserDefaults`, with one test.

**Files:**
- Create: `DroneDelivery/Persistence/SaveData.swift`
- Create: `DroneDeliveryTests/SaveDataTests.swift`

**Interfaces produced:**
- `struct SaveData: Codable, Sendable { var completedMissionIDs: Set<String>; var bestScore: [String: Int]; var settings: Settings }`
- `struct Settings: Codable, Sendable { var gyroEnabled: Bool; var useImperialUnits: Bool }`
- `enum SaveStore { static func load() -> SaveData; static func save(_ d: SaveData) }`

- [ ] **Step 1: Write the failing test**

`DroneDeliveryTests/SaveDataTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the test, verify it fails (types missing)**

⌘U. Expected: fails with "cannot find 'SaveData' in scope."

- [ ] **Step 3: Create `Persistence/SaveData.swift`**

```swift
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
```

- [ ] **Step 4: Run the test, verify it passes**

⌘U. Expected: `roundTripsThroughDefaults` passes.

- [ ] **Step 5: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- SaveData + SaveStore: UserDefaults-backed Codable persistence with round-trip test.
```

```bash
git add -A
git commit -m "Add SaveData persistence with round-trip test"
```

---

## Task 5: Mission catalog and MissionStore

**Goal:** Three missions defined in JSON; `MissionStore` loads them, tracks unlocked/completed, persists via `SaveStore`. Tested for parse correctness and unlock graph integrity.

**Files:**
- Create: `DroneDelivery/Mission/Missions.json` (added to bundle resources)
- Create: `DroneDelivery/Airspace/Airspace.json` (zones referenced by missions)
- Create: `DroneDelivery/Mission/MissionStore.swift`
- Create: `DroneDeliveryTests/MissionStoreTests.swift`

**Interfaces produced:**
- `@Observable final class MissionStore { var unlocked: Set<String>; var completed: Set<String>; func mission(id: String) -> Mission?; var all: [Mission]; var zones: [String: AirspaceZone]; func complete(id: String, score: Int); init(defaults: UserDefaults = .standard) }`

- [ ] **Step 1: Create `Mission/Missions.json` with three missions**

```json
[
  {
    "id": "m01_calm_pizza",
    "cargoTheme": "pizza",
    "pickup": { "position": [-40, 0, -40], "label": "Tony's Pizza" },
    "dropoff": { "position": [40, 0, 40], "label": "Maple St #14" },
    "conditions": {
      "weather": { "windKts": 0, "windDir": 0, "visibilitySM": 10, "ceilingFtAGL": 12000, "temperatureC": 22, "densityAltitudeFt": 800 },
      "airspace": ["G_open"],
      "notams": [],
      "batteryWh": 80,
      "timeOfDay": "day"
    },
    "unlockAfter": null
  },
  {
    "id": "m02_crosswind_grocery",
    "cargoTheme": "groceries",
    "pickup": { "position": [-40, 0, 0], "label": "Marshall Grocery" },
    "dropoff": { "position": [40, 0, -30], "label": "Elm St #22" },
    "conditions": {
      "weather": { "windKts": 12, "windDir": 270, "visibilitySM": 10, "ceilingFtAGL": 8000, "temperatureC": 18, "densityAltitudeFt": 1200 },
      "airspace": ["G_open"],
      "notams": [],
      "batteryWh": 65,
      "timeOfDay": "day"
    },
    "unlockAfter": "m01_calm_pizza"
  },
  {
    "id": "m03_class_b_notam",
    "cargoTheme": "video",
    "pickup": { "position": [-40, 0, 40], "label": "News Bureau" },
    "dropoff": { "position": [40, 0, -40], "label": "Stadium Cam Position" },
    "conditions": {
      "weather": { "windKts": 8, "windDir": 180, "visibilitySM": 6, "ceilingFtAGL": 4500, "temperatureC": 24, "densityAltitudeFt": 2200 },
      "airspace": ["G_open", "B_authorized"],
      "notams": [
        {
          "id": "NOTAM_STADIUM_EVENT",
          "reason": "TFR — stadium event",
          "polygon": [[-10, -10], [10, -10], [10, 10], [-10, 10]],
          "floorAGL": 0,
          "ceilingAGL": 400,
          "start": "2026-06-27T00:00:00Z",
          "end": "2099-12-31T00:00:00Z"
        }
      ],
      "batteryWh": 70,
      "timeOfDay": "day"
    },
    "unlockAfter": "m02_crosswind_grocery"
  }
]
```

- [ ] **Step 2: Create `Airspace/Airspace.json`**

```json
[
  {
    "id": "G_open",
    "polygonName": "City open ground",
    "class": "g",
    "polygon": [[-60, -60], [60, -60], [60, 60], [-60, 60]],
    "floorAGL": 0,
    "ceilingAGL": 400,
    "requiresAuthorization": false
  },
  {
    "id": "B_authorized",
    "polygonName": "Class B sliver — authorization on file",
    "class": "b",
    "polygon": [[20, -60], [60, -60], [60, 60], [20, 60]],
    "floorAGL": 0,
    "ceilingAGL": 400,
    "requiresAuthorization": true
  }
]
```

- [ ] **Step 3: Add both JSON files to the Xcode bundle**

In Xcode, drag both files into their respective groups. In the dialog: **Copy items if needed** off (already in tree), **Add to targets: DroneDelivery** checked.

- [ ] **Step 4: Write the failing test**

`DroneDeliveryTests/MissionStoreTests.swift`:

```swift
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
```

- [ ] **Step 5: Run, verify it fails (MissionStore doesn't exist)**

⌘U. Expected: fails with "cannot find 'MissionStore'."

- [ ] **Step 6: Create `Mission/MissionStore.swift`**

```swift
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
        self.completed = save.completedMissionIDs

        self.all = Self.loadBundled([Mission].self, named: "Missions")
        let zoneList: [AirspaceZone] = Self.loadBundled([AirspaceZone].self, named: "Airspace")
        self.zones = Dictionary(uniqueKeysWithValues: zoneList.map { ($0.id, $0) })

        self.unlocked = Self.computeUnlocked(all: all, completed: completed)
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
```

- [ ] **Step 7: Run, verify tests pass**

⌘U. Expected: all four tests pass.

- [ ] **Step 8: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- Three Phase 1 missions (Missions.json) + airspace zones (Airspace.json).
- MissionStore (@Observable): loads bundle, tracks unlocked/completed, persists via SaveStore.
```

```bash
git add -A
git commit -m "Add MissionStore with three missions and unlock graph test"
```

---

## Task 6: RealityKit components and KinematicSystem

**Goal:** All five Component structs registered, `KinematicSystem` running per-frame integration with tests for the pure-math helpers (velocity step, battery drain).

**Files:**
- Create: `DroneDelivery/Drone/DroneComponents.swift`
- Create: `DroneDelivery/Drone/KinematicSystem.swift`
- Create: `DroneDeliveryTests/KinematicMathTests.swift`

**Interfaces produced:**
- `struct KinematicComponent: Component { var velocity, targetVelocity: SIMD3<Float>; var maxSpeed: Float }`
- `struct BatteryComponent: Component { var remainingWh: Double; let capacityWh: Double }`
- `struct AltimeterComponent: Component { var aglFt: Float }`
- `struct WindComponent: Component { var vector: SIMD3<Float> }`  (mounted on the scene root, not the drone)
- `struct CargoComponent: Component { let kind: CargoKind; var delivered: Bool }`
- `enum KinematicMath { static func stepVelocity(current: SIMD3<Float>, target: SIMD3<Float>, lerp: Float) -> SIMD3<Float>; static func drainW(speedMS: Float, windKts: Float) -> Double }`
- `final class KinematicSystem: System` — subscribed via `KinematicSystem.registerSystem()`.

- [ ] **Step 1: Write failing tests for the pure-math helpers**

`DroneDeliveryTests/KinematicMathTests.swift`:

```swift
import Testing
import simd
@testable import DroneDelivery

@Suite struct KinematicMathTests {
    @Test func stepVelocityMovesTowardTarget() {
        let result = KinematicMath.stepVelocity(
            current: SIMD3(0, 0, 0),
            target: SIMD3(10, 0, 0),
            lerp: 0.5
        )
        #expect(result.x == 5)
    }

    @Test func stepVelocityHonorsLerpZero() {
        let result = KinematicMath.stepVelocity(
            current: SIMD3(3, 0, 0),
            target: SIMD3(10, 0, 0),
            lerp: 0
        )
        #expect(result == SIMD3(3, 0, 0))
    }

    @Test func drainIncreasesWithSpeed() {
        let still = KinematicMath.drainW(speedMS: 0, windKts: 0)
        let fast = KinematicMath.drainW(speedMS: 10, windKts: 0)
        #expect(fast > still)
    }

    @Test func drainIncreasesWithWind() {
        let calm = KinematicMath.drainW(speedMS: 5, windKts: 0)
        let windy = KinematicMath.drainW(speedMS: 5, windKts: 15)
        #expect(windy > calm)
    }
}
```

- [ ] **Step 2: Run, verify tests fail**

⌘U. Expected: fails — `KinematicMath` doesn't exist yet.

- [ ] **Step 3: Create `Drone/DroneComponents.swift`**

```swift
import RealityKit
import simd

public struct KinematicComponent: Component {
    public var velocity: SIMD3<Float>
    public var targetVelocity: SIMD3<Float>
    public var maxSpeed: Float
    public init(velocity: SIMD3<Float> = .zero,
                targetVelocity: SIMD3<Float> = .zero,
                maxSpeed: Float = PhysicsTuning.maxSpeedMS) {
        self.velocity = velocity
        self.targetVelocity = targetVelocity
        self.maxSpeed = maxSpeed
    }
}

public struct BatteryComponent: Component {
    public var remainingWh: Double
    public let capacityWh: Double
    public init(capacityWh: Double) {
        self.capacityWh = capacityWh
        self.remainingWh = capacityWh
    }
}

public struct AltimeterComponent: Component {
    public var aglFt: Float = 0
    public init() {}
}

public struct WindComponent: Component {
    public var vector: SIMD3<Float>
    public init(vector: SIMD3<Float> = .zero) { self.vector = vector }
}

public struct CargoComponent: Component {
    public let kind: CargoKind
    public var delivered: Bool
    public init(kind: CargoKind, delivered: Bool = false) {
        self.kind = kind
        self.delivered = delivered
    }
}

public enum DroneComponents {
    public static func registerAll() {
        KinematicComponent.registerComponent()
        BatteryComponent.registerComponent()
        AltimeterComponent.registerComponent()
        WindComponent.registerComponent()
        CargoComponent.registerComponent()
    }
}
```

- [ ] **Step 4: Create `Drone/KinematicSystem.swift`**

```swift
import RealityKit
import simd

public enum KinematicMath {
    public static func stepVelocity(current: SIMD3<Float>,
                                    target: SIMD3<Float>,
                                    lerp: Float) -> SIMD3<Float> {
        current + (target - current) * lerp
    }

    public static func drainW(speedMS: Float, windKts: Float) -> Double {
        PhysicsTuning.baseDrainW
            + Double(speedMS) * PhysicsTuning.perMSDrainW
            + Double(abs(windKts)) * PhysicsTuning.perKtWindFightDrainW
    }
}

public final class KinematicSystem: System {
    private static let droneQuery = EntityQuery(where: .has(KinematicComponent.self))
    private static let windQuery = EntityQuery(where: .has(WindComponent.self))

    public required init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)

        let wind: SIMD3<Float> = context.scene
            .performQuery(Self.windQuery)
            .compactMap { $0.components[WindComponent.self]?.vector }
            .first ?? .zero

        context.scene.performQuery(Self.droneQuery).forEach { entity in
            guard var kin = entity.components[KinematicComponent.self] else { return }

            // Velocity smoothing toward target.
            kin.velocity = KinematicMath.stepVelocity(
                current: kin.velocity,
                target: kin.targetVelocity,
                lerp: PhysicsTuning.velocityLerp
            )

            // Clamp to max speed.
            let speed = simd_length(kin.velocity)
            if speed > kin.maxSpeed {
                kin.velocity = (kin.velocity / speed) * kin.maxSpeed
            }

            // Integrate position, adding the wind transfer.
            let effective = kin.velocity + wind * PhysicsTuning.windCoupling
            entity.position += effective * dt

            entity.components.set(kin)

            // Altimeter (flat ground = y=0 in scene space).
            if var alt = entity.components[AltimeterComponent.self] {
                alt.aglFt = entity.position.y * PhysicsTuning.metresToFeet
                entity.components.set(alt)
            }

            // Battery drain.
            if var bat = entity.components[BatteryComponent.self] {
                let speedMS = simd_length(kin.velocity)
                let windKts = simd_length(wind) / PhysicsTuning.knotsToMS
                let drain = KinematicMath.drainW(speedMS: speedMS, windKts: windKts)
                bat.remainingWh = max(0, bat.remainingWh - drain * Double(dt) / 3600.0)
                entity.components.set(bat)
            }
        }
    }
}
```

- [ ] **Step 5: Run, verify all KinematicMath tests pass**

⌘U. Expected: all four `KinematicMathTests` pass.

- [ ] **Step 6: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- RealityKit components (Kinematic, Battery, Altimeter, Wind, Cargo) + registration.
- KinematicSystem with per-frame velocity smoothing, wind transfer, altitude, battery drain.
- KinematicMath helpers with tests.
```

```bash
git add -A
git commit -m "Add KinematicSystem with components and math tests"
```

---

## Task 7: AppState

**Goal:** The `@Observable` root state SwiftUI reads from and the System mirrors into.

**Files:**
- Create: `DroneDelivery/App/AppState.swift`

**Interfaces produced:**
- `@Observable final class AppState { var phase: GamePhase; var currentMission: Mission?; var currentAirspaceID: String?; var batteryPercent: Double; var altitudeAGLFt: Float; var paused: Bool; var failureReason: String?; var score: Int }`

- [ ] **Step 1: Create `App/AppState.swift`**

```swift
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
```

- [ ] **Step 2: Build to confirm clean**

⌘B. Expected: clean build.

- [ ] **Step 3: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- AppState (@Observable): root state read by views, mirrored by KinematicSystem.
```

```bash
git add -A
git commit -m "Add AppState root observable"
```

---

## Task 8: FlightInput and virtual thumbsticks

**Goal:** A reusable virtual thumbstick view and an `@Observable` `FlightInput` holding the left/right stick vectors that the System reads to set `targetVelocity`.

**Files:**
- Create: `DroneDelivery/Flight/FlightInput.swift`
- Create: `DroneDelivery/Flight/Thumbstick.swift`

**Interfaces produced:**
- `@Observable final class FlightInput { var leftStick: SIMD2<Float>; var rightStick: SIMD2<Float> }`  (each stick component in [-1, 1])
- `struct Thumbstick: View { @Binding var value: SIMD2<Float>; let radius: CGFloat; let label: String }`

- [ ] **Step 1: Create `Flight/FlightInput.swift`**

```swift
import Foundation
import Observation
import simd

@Observable
public final class FlightInput {
    public var leftStick: SIMD2<Float> = .zero    // x = strafe, y = forward
    public var rightStick: SIMD2<Float> = .zero   // x = yaw, y = altitude

    public init() {}

    /// Map stick input to a target velocity in scene space.
    public func targetVelocity(maxSpeed: Float) -> SIMD3<Float> {
        let horizontal = SIMD3<Float>(leftStick.x, rightStick.y, -leftStick.y) * maxSpeed
        return horizontal
    }
}
```

(Right-stick X / yaw is wired in Task 9 if a yaw mechanic is added; for Phase 1 the camera follows the drone, so yaw is not implemented and right-stick.x is ignored. `// ponytail: yaw deferred to Phase 2; right-stick.x reserved.`)

- [ ] **Step 2: Create `Flight/Thumbstick.swift`**

```swift
import SwiftUI
import simd

public struct Thumbstick: View {
    @Binding public var value: SIMD2<Float>
    public let radius: CGFloat
    public let label: String

    @State private var knob: CGSize = .zero

    public init(value: Binding<SIMD2<Float>>, radius: CGFloat = 60, label: String) {
        self._value = value
        self.radius = radius
        self.label = label
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: radius * 0.7, height: radius * 0.7)
                .offset(knob)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let clamped = clamp(g.translation, to: radius)
                            knob = clamped
                            value = SIMD2<Float>(
                                Float(clamped.width / radius),
                                Float(-clamped.height / radius)    // up = +y
                            )
                        }
                        .onEnded { _ in
                            withAnimation(.spring(duration: 0.15)) { knob = .zero }
                            value = .zero
                        }
                )

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .offset(y: radius + 12)
        }
        .frame(width: radius * 2, height: radius * 2)
    }

    private func clamp(_ s: CGSize, to r: CGFloat) -> CGSize {
        let d = sqrt(s.width * s.width + s.height * s.height)
        if d <= r { return s }
        let scale = r / d
        return CGSize(width: s.width * scale, height: s.height * scale)
    }
}

#Preview {
    @Previewable @State var v: SIMD2<Float> = .zero
    return Thumbstick(value: $v, label: "Move")
        .padding(40)
        .background(.black)
}
```

- [ ] **Step 3: Build and verify the Preview**

In Xcode, open `Thumbstick.swift`, open the Preview canvas (⌥⌘↩). Expected: a circle with a draggable inner knob renders on a black background.

- [ ] **Step 4: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- FlightInput (@Observable) + virtual Thumbstick SwiftUI view.
```

```bash
git add -A
git commit -m "Add FlightInput and Thumbstick view"
```

---

## Task 9: Drone factory and placeholder city scene

**Goal:** Two factory functions — `makeDrone()` and `makeCity()` — that produce ready-to-mount RealityKit entities. The city is programmatic: a green ground plane, four cuboid "buildings," and pickup/dropoff markers for the current mission. **First runnable build with a flying drone is the next task; this task ships the geometry.**

**Files:**
- Create: `DroneDelivery/Drone/DroneEntity.swift`
- Create: `DroneDelivery/Scenes/City/CityEntities.swift`

**Interfaces produced:**
- `func makeDrone(cargo: CargoKind, batteryWh: Double) -> Entity`
- `func makeCity(pickup: Waypoint, dropoff: Waypoint) -> Entity`

- [ ] **Step 1: Create `Drone/DroneEntity.swift`**

```swift
import RealityKit
import simd

public func makeDrone(cargo: CargoKind, batteryWh: Double) -> Entity {
    let body = ModelEntity(
        mesh: .generateBox(size: SIMD3<Float>(0.6, 0.18, 0.6), cornerRadius: 0.06),
        materials: [SimpleMaterial(color: .darkGray, isMetallic: true)]
    )

    // Four arms + propeller stubs as visual signal.
    for sign in [SIMD2<Float>(1,1), SIMD2(-1,1), SIMD2(1,-1), SIMD2(-1,-1)] {
        let arm = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.06, 0.04, 0.06)),
            materials: [SimpleMaterial(color: .black, isMetallic: false)]
        )
        arm.position = SIMD3<Float>(sign.x * 0.34, 0.04, sign.y * 0.34)
        body.addChild(arm)

        let prop = ModelEntity(
            mesh: .generateCylinder(height: 0.01, radius: 0.18),
            materials: [SimpleMaterial(color: .white.withAlphaComponent(0.5), isMetallic: false)]
        )
        prop.position = SIMD3<Float>(sign.x * 0.34, 0.08, sign.y * 0.34)
        body.addChild(prop)
    }

    body.components.set(KinematicComponent())
    body.components.set(BatteryComponent(capacityWh: batteryWh))
    body.components.set(AltimeterComponent())
    body.components.set(CargoComponent(kind: cargo))
    body.components.set(CollisionComponent(
        shapes: [.generateBox(size: SIMD3<Float>(0.7, 0.2, 0.7))],
        mode: .trigger,
        filter: .default
    ))

    body.position = SIMD3<Float>(0, 5, 0)   // start 5 m up
    return body
}
```

- [ ] **Step 2: Create `Scenes/City/CityEntities.swift`**

```swift
import RealityKit
import simd
import UIKit

public func makeCity(pickup: Waypoint, dropoff: Waypoint) -> Entity {
    let root = Entity()
    root.components.set(WindComponent())   // overwritten per-mission

    // Ground: 200 x 200 m. No CollisionComponent — landing on open ground is a
    // delivery attempt, not a crash. Building collisions fail the mission instead.
    let ground = ModelEntity(
        mesh: .generatePlane(width: 200, depth: 200),
        materials: [SimpleMaterial(color: UIColor(red: 0.16, green: 0.38, blue: 0.22, alpha: 1), isMetallic: false)]
    )
    ground.position = SIMD3<Float>(0, 0, 0)
    root.addChild(ground)

    // Four placeholder buildings.
    let buildings: [(SIMD3<Float>, SIMD3<Float>)] = [
        (SIMD3(-15, 6, -15), SIMD3(8, 12, 8)),
        (SIMD3(15, 8, -15),  SIMD3(10, 16, 8)),
        (SIMD3(-15, 5, 15),  SIMD3(8, 10, 8)),
        (SIMD3(15, 7, 15),   SIMD3(10, 14, 8)),
    ]
    for (center, size) in buildings {
        let b = ModelEntity(
            mesh: .generateBox(size: size),
            materials: [SimpleMaterial(color: .lightGray, isMetallic: false)]
        )
        b.position = center
        b.components.set(CollisionComponent(
            shapes: [.generateBox(size: size)],
            mode: .trigger,
            filter: .default
        ))
        root.addChild(b)
    }

    // Pickup marker — green pole.
    root.addChild(makeMarker(at: pickup.position, color: .systemGreen))
    // Dropoff marker — orange pole.
    root.addChild(makeMarker(at: dropoff.position, color: .systemOrange))

    return root
}

private func makeMarker(at p: SIMD3<Float>, color: UIColor) -> Entity {
    let pole = ModelEntity(
        mesh: .generateCylinder(height: 8, radius: 0.2),
        materials: [SimpleMaterial(color: color, isMetallic: false)]
    )
    pole.position = SIMD3<Float>(p.x, 4, p.z)
    return pole
}
```

- [ ] **Step 3: Build to confirm clean**

⌘B. Expected: clean build.

- [ ] **Step 4: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- makeDrone() and makeCity() factories with programmatic placeholder geometry.
```

```bash
git add -A
git commit -m "Add drone and city entity factories"
```

---

## Task 10: CityScene RealityView wrapper (first runnable flight)

**Goal:** Wire components + system + drone + input + AppState into a single `RealityView`. This task ends with **the drone flying on a simulator**.

**Files:**
- Create: `DroneDelivery/Scenes/City/CityScene.swift`

**Interfaces produced:**
- `struct CityScene: View { @Bindable var state: AppState; @Bindable var input: FlightInput; let mission: Mission; let zones: [String: AirspaceZone] }`

- [ ] **Step 1: Create `Scenes/City/CityScene.swift`**

```swift
import SwiftUI
import RealityKit
import simd

public struct CityScene: View {
    @Bindable public var state: AppState
    @Bindable public var input: FlightInput
    public let mission: Mission
    public let zones: [String: AirspaceZone]

    @State private var collisionSubscription: EventSubscription?

    public init(state: AppState, input: FlightInput, mission: Mission, zones: [String: AirspaceZone]) {
        self.state = state
        self.input = input
        self.mission = mission
        self.zones = zones
    }

    public var body: some View {
        RealityView { content in
            DroneComponents.registerAll()
            KinematicSystem.registerSystem()

            let city = makeCity(pickup: mission.pickup, dropoff: mission.dropoff)
            applyWind(city: city)
            content.add(city)

            let drone = makeDrone(cargo: mission.cargoTheme, batteryWh: mission.conditions.batteryWh)
            drone.position = mission.pickup.position + SIMD3<Float>(0, 5, 0)
            content.add(drone)

            // Camera follows the drone from behind/above.
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 70
            camera.position = SIMD3<Float>(0, 8, 12)
            drone.addChild(camera)

            // Collision = fail. Drone uses .sensor filter; buildings/ground use .default.
            collisionSubscription = content.subscribe(to: CollisionEvents.Began.self) { event in
                let droneHit = event.entityA.components.has(KinematicComponent.self)
                              || event.entityB.components.has(KinematicComponent.self)
                guard droneHit, state.phase == .flying else { return }
                fail("Collision detected — flight ended")
            }
        } update: { content in
            updateDroneTarget(content: content)
            mirrorIntoState(content: content)
            evaluateFailures(content: content)
        }
        .ignoresSafeArea()
    }

    private func applyWind(city: Entity) {
        let kts = mission.conditions.weather.windKts
        let dir = mission.conditions.weather.windDir * .pi / 180
        let v = SIMD3<Float>(sin(dir), 0, cos(dir)) * kts * PhysicsTuning.knotsToMS
        city.components.set(WindComponent(vector: v))
    }

    private func updateDroneTarget(content: RealityViewContent) {
        guard !state.paused else { return }
        for entity in content.entities where entity.components.has(KinematicComponent.self) {
            var k = entity.components[KinematicComponent.self]!
            k.targetVelocity = input.targetVelocity(maxSpeed: k.maxSpeed)
            entity.components.set(k)
        }
    }

    private func mirrorIntoState(content: RealityViewContent) {
        for entity in content.entities {
            if let bat = entity.components[BatteryComponent.self] {
                state.batteryPercent = (bat.remainingWh / bat.capacityWh) * 100
            }
            if let alt = entity.components[AltimeterComponent.self] {
                state.altitudeAGLFt = alt.aglFt
            }
            if entity.components.has(KinematicComponent.self) {
                let p = SIMD2<Float>(entity.position.x, entity.position.z)
                state.currentAirspaceID = mission.conditions.airspace
                    .compactMap { zones[$0] }
                    .first { $0.contains(p) }
                    .map(\.id)
            }
        }
    }

    private func evaluateFailures(content: RealityViewContent) {
        guard state.phase == .flying else { return }

        // CFR § 107.51(b): max 400 ft AGL.
        if state.altitudeAGLFt > PhysicsTuning.maxAltitudeAGLFt {
            fail("Altitude bust: exceeded 400 ft AGL (14 CFR § 107.51(b))")
            return
        }

        // Battery depleted.
        if state.batteryPercent <= 0 {
            fail("Battery depleted before delivery (return-to-home failure)")
            return
        }

        // Unauthorized zone entry.
        if let id = state.currentAirspaceID,
           let zone = zones[id],
           zone.requiresAuthorization,
           !mission.conditions.airspace.contains(id) {
            fail("Entered \(zone.class.rawValue.uppercased()) without authorization")
            return
        }

        // NOTAM intrusion.
        for entity in content.entities where entity.components.has(KinematicComponent.self) {
            let p = SIMD2<Float>(entity.position.x, entity.position.z)
            for notam in mission.conditions.notams where notam.contains(p) {
                fail("Entered active NOTAM: \(notam.reason)")
                return
            }
        }
    }

    private func fail(_ reason: String) {
        state.failureReason = reason
        state.phase = .debrief
    }
}
```

- [ ] **Step 2: Temporary harness — swap the App entry to mount CityScene**

Modify `App/DroneDeliveryApp.swift`:

```swift
import SwiftUI

@main
struct DroneDeliveryApp: App {
    @State private var store = MissionStore()
    @State private var state = AppState()
    @State private var input = FlightInput()

    var body: some Scene {
        WindowGroup {
            HarnessView(store: store, state: state, input: input)
        }
    }
}

private struct HarnessView: View {
    let store: MissionStore
    @Bindable var state: AppState
    @Bindable var input: FlightInput

    var body: some View {
        let mission = store.all.first!
        ZStack {
            CityScene(state: state, input: input, mission: mission, zones: store.zones)
            VStack {
                Spacer()
                HStack {
                    Thumbstick(value: $input.leftStick, label: "Move").padding()
                    Spacer()
                    Thumbstick(value: $input.rightStick, label: "Alt").padding()
                }
            }
        }
        .onAppear {
            state.currentMission = mission
            state.phase = .flying
        }
    }
}
```

- [ ] **Step 3: Run on iPhone simulator**

⌘R, iPhone 15 simulator. Expected:

- A green field with four gray buildings renders.
- Green and orange poles mark pickup/dropoff for `m01_calm_pizza`.
- A small dark drone hovers above the pickup pole.
- Dragging the left thumbstick moves the drone horizontally.
- Dragging the right thumbstick (up = altitude up) raises/lowers the drone.

If the drone doesn't move: re-check that `KinematicSystem.registerSystem()` is called and that `update:` runs (add a `print` if needed).

- [ ] **Step 4: Manually test failure conditions**

While running:

1. Fly straight up. After altimeter passes 400 ft, expect the app to transition to `.debrief` phase. (Debrief screen is wired in Task 12 — for now the harness will just freeze; check `state.failureReason` is set via the debugger or a temporary text overlay.)
2. Stop input and wait. Battery should drain (visible if you add `Text("\(state.batteryPercent)").foregroundStyle(.white)` to the overlay temporarily). It should fail at 0.

- [ ] **Step 5: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- CityScene RealityView wrapper: mounts drone+city, drives KinematicSystem, evaluates failures.
- First runnable Phase 1 build: drone flies via virtual thumbsticks, with diegetic Part 107 enforcement.
```

```bash
git add -A
git commit -m "Add CityScene with first runnable drone flight"
```

---

## Task 11: HUDView

**Goal:** A SwiftUI overlay shown during `.flying` that displays altitude AGL, airspace class chip, battery %, wind, and the two thumbsticks. Includes a pause button.

**Files:**
- Create: `DroneDelivery/UI/HUDView.swift`

**Interfaces produced:**
- `struct HUDView: View { @Bindable var state: AppState; @Bindable var input: FlightInput; let weather: WeatherSpec; let zones: [String: AirspaceZone]; let onPause: () -> Void; let onHelp: () -> Void }`

- [ ] **Step 1: Create `UI/HUDView.swift`**

```swift
import SwiftUI

public struct HUDView: View {
    @Bindable public var state: AppState
    @Bindable public var input: FlightInput
    public let weather: WeatherSpec
    public let zones: [String: AirspaceZone]
    public let onPause: () -> Void
    public let onHelp: () -> Void

    public init(state: AppState, input: FlightInput, weather: WeatherSpec,
                zones: [String: AirspaceZone], onPause: @escaping () -> Void,
                onHelp: @escaping () -> Void) {
        self.state = state
        self.input = input
        self.weather = weather
        self.zones = zones
        self.onPause = onPause
        self.onHelp = onHelp
    }

    public var body: some View {
        VStack {
            topStrip
            Spacer()
            bottomControls
        }
        .padding()
    }

    private var topStrip: some View {
        HStack {
            chip("ALT", "\(Int(state.altitudeAGLFt)) ft", warn: state.altitudeAGLFt > 350)
            chip("AIRSPACE", airspaceLabel)
            chip("BATT", "\(Int(state.batteryPercent))%", warn: state.batteryPercent < 25)
            chip("WIND", "\(Int(weather.windKts)) kt / \(Int(weather.windDir))°")
            Spacer()
            Button(action: onHelp) { Image(systemName: "questionmark.circle") }
                .foregroundStyle(.white)
            Button(action: onPause) { Image(systemName: "pause.circle") }
                .foregroundStyle(.white)
        }
    }

    private var bottomControls: some View {
        HStack {
            Thumbstick(value: $input.leftStick, label: "Move")
            Spacer()
            Thumbstick(value: $input.rightStick, label: "Alt")
        }
    }

    private var airspaceLabel: String {
        guard let id = state.currentAirspaceID, let z = zones[id] else { return "—" }
        return "Class \(z.class.rawValue.uppercased())"
    }

    private func chip(_ title: String, _ value: String, warn: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.6))
            Text(value).font(.headline).foregroundStyle(warn ? .red : .white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.black.opacity(0.5), in: .rect(cornerRadius: 8))
    }
}

#Preview {
    let state = AppState()
    state.altitudeAGLFt = 250
    state.batteryPercent = 67
    state.currentAirspaceID = "G_open"
    let zones = ["G_open": AirspaceZone(id: "G_open", polygonName: "x", class: .g,
                                         polygon: [.zero], floorAGL: 0, ceilingAGL: 400,
                                         requiresAuthorization: false)]
    let weather = WeatherSpec(windKts: 8, windDir: 270, visibilitySM: 10,
                              ceilingFtAGL: 8000, temperatureC: 18, densityAltitudeFt: 1200)
    return HUDView(state: state, input: FlightInput(), weather: weather,
                   zones: zones, onPause: {}, onHelp: {})
        .background(.green)
}
```

- [ ] **Step 2: Verify Preview renders**

Open `HUDView.swift`, open Preview canvas. Expected: chips show ALT/AIRSPACE/BATT/WIND at top, thumbsticks at bottom corners.

- [ ] **Step 3: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- HUDView: altitude/airspace/battery/wind chips + thumbsticks + pause/help buttons.
```

```bash
git add -A
git commit -m "Add HUDView"
```

---

## Task 12: MainMenu, Briefing, Debrief

**Goal:** Three SwiftUI screens for the mission flow outside of `.flying`.

**Files:**
- Create: `DroneDelivery/UI/MainMenuView.swift`
- Create: `DroneDelivery/UI/BriefingView.swift`
- Create: `DroneDelivery/UI/DebriefView.swift`
- Create: `DroneDelivery/UI/SectionalMap.swift`  (small `Canvas` helper used by BriefingView)

**Interfaces produced:**
- `struct MainMenuView: View { let store: MissionStore; let onPick: (Mission) -> Void }`
- `struct BriefingView: View { let mission: Mission; let zones: [String: AirspaceZone]; let onLaunch: () -> Void }`
- `struct DebriefView: View { let mission: Mission; let success: Bool; let failureReason: String?; let score: Int; let onRetry: () -> Void; let onNext: (() -> Void)?; let onMenu: () -> Void }`
- `struct SectionalMap: View { let mission: Mission; let zones: [String: AirspaceZone] }`

- [ ] **Step 1: Create `UI/MainMenuView.swift`**

```swift
import SwiftUI

public struct MainMenuView: View {
    public let store: MissionStore
    public let onPick: (Mission) -> Void

    public init(store: MissionStore, onPick: @escaping (Mission) -> Void) {
        self.store = store
        self.onPick = onPick
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Missions") {
                    ForEach(store.all) { m in
                        let unlocked = store.unlocked.contains(m.id)
                        Button {
                            if unlocked { onPick(m) }
                        } label: {
                            HStack {
                                Image(systemName: unlocked ? "airplane" : "lock.fill")
                                VStack(alignment: .leading) {
                                    Text(m.cargoTheme.rawValue.capitalized).font(.headline)
                                    Text(m.id).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if store.completed.contains(m.id) {
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                }
                            }
                        }
                        .disabled(!unlocked)
                    }
                }
            }
            .navigationTitle("DroneDelivery")
        }
    }
}

#Preview { MainMenuView(store: MissionStore(), onPick: { _ in }) }
```

- [ ] **Step 2: Create `UI/SectionalMap.swift`**

```swift
import SwiftUI
import simd

public struct SectionalMap: View {
    public let mission: Mission
    public let zones: [String: AirspaceZone]

    public init(mission: Mission, zones: [String: AirspaceZone]) {
        self.mission = mission
        self.zones = zones
    }

    public var body: some View {
        Canvas { ctx, size in
            let bounds: ClosedRange<Float> = -60...60
            let span = bounds.upperBound - bounds.lowerBound
            func toScreen(_ p: SIMD2<Float>) -> CGPoint {
                CGPoint(
                    x: CGFloat((p.x - bounds.lowerBound) / span) * size.width,
                    y: CGFloat((p.y - bounds.lowerBound) / span) * size.height
                )
            }

            // Zones.
            for id in mission.conditions.airspace {
                guard let z = zones[id] else { continue }
                var path = Path()
                let pts = z.polygon.map(toScreen)
                if let first = pts.first {
                    path.move(to: first)
                    for p in pts.dropFirst() { path.addLine(to: p) }
                    path.closeSubpath()
                }
                let fill: Color = z.class == .b ? .blue.opacity(0.25)
                                : z.class == .c ? .magenta.opacity(0.25)
                                : .green.opacity(0.15)
                ctx.fill(path, with: .color(fill))
                ctx.stroke(path, with: .color(fill.opacity(0.8)), lineWidth: 1)
            }

            // NOTAMs (red).
            for n in mission.conditions.notams {
                var path = Path()
                let pts = n.polygon.map(toScreen)
                if let first = pts.first {
                    path.move(to: first)
                    for p in pts.dropFirst() { path.addLine(to: p) }
                    path.closeSubpath()
                }
                ctx.fill(path, with: .color(.red.opacity(0.35)))
                ctx.stroke(path, with: .color(.red), lineWidth: 1)
            }

            // Pickup (green) + Dropoff (orange) + line between.
            let p = toScreen(SIMD2(mission.pickup.position.x, mission.pickup.position.z))
            let d = toScreen(SIMD2(mission.dropoff.position.x, mission.dropoff.position.z))
            var route = Path(); route.move(to: p); route.addLine(to: d)
            ctx.stroke(route, with: .color(.white), style: .init(lineWidth: 1, dash: [4, 4]))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(.green))
            ctx.fill(Path(ellipseIn: CGRect(x: d.x - 4, y: d.y - 4, width: 8, height: 8)), with: .color(.orange))
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.black)
    }
}
```

- [ ] **Step 3: Create `UI/BriefingView.swift`**

```swift
import SwiftUI

public struct BriefingView: View {
    public let mission: Mission
    public let zones: [String: AirspaceZone]
    public let onLaunch: () -> Void

    public init(mission: Mission, zones: [String: AirspaceZone], onLaunch: @escaping () -> Void) {
        self.mission = mission
        self.zones = zones
        self.onLaunch = onLaunch
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Briefing").font(.largeTitle.bold())

                section("Today's flight") {
                    Text("Cargo: \(mission.cargoTheme.rawValue.capitalized)")
                    Text("From \(mission.pickup.label) → \(mission.dropoff.label)")
                    SectionalMap(mission: mission, zones: zones).frame(maxWidth: 360)
                }

                section("Weather") {
                    let w = mission.conditions.weather
                    Text("Wind \(Int(w.windKts)) kt @ \(Int(w.windDir))° true")
                    Text("Visibility \(String(format: "%.0f", w.visibilitySM)) SM")
                    Text("Ceiling \(Int(w.ceilingFtAGL)) ft AGL")
                    Text("Density altitude \(Int(w.densityAltitudeFt)) ft")
                }

                section("Airspace & NOTAMs") {
                    ForEach(mission.conditions.airspace, id: \.self) { id in
                        if let z = zones[id] {
                            HStack {
                                Text("Class \(z.class.rawValue.uppercased())")
                                if z.requiresAuthorization {
                                    Text("authorization on file").italic().foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    ForEach(mission.conditions.notams) { n in
                        Text("NOTAM — \(n.reason)").foregroundStyle(.red)
                    }
                }

                section("Aircraft") {
                    Text("Battery budget: \(Int(mission.conditions.batteryWh)) Wh")
                    Text("Time of day: \(mission.conditions.timeOfDay.rawValue)")
                }

                section("Limits in play (cite each)") {
                    Text("Max altitude 400 ft AGL — 14 CFR § 107.51(b)")
                    Text("No flight in unauthorized controlled airspace — 14 CFR § 107.41")
                    Text("Active NOTAMs / TFRs apply — 14 CFR § 107.49")
                }

                Button("Go fly", action: onLaunch)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding()
        }
    }

    @ViewBuilder private func section(_ title: String, @ViewBuilder body: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            body()
        }
        .padding()
        .background(.gray.opacity(0.1), in: .rect(cornerRadius: 8))
    }
}
```

- [ ] **Step 4: Create `UI/DebriefView.swift`**

```swift
import SwiftUI

public struct DebriefView: View {
    public let mission: Mission
    public let success: Bool
    public let failureReason: String?
    public let score: Int
    public let onRetry: () -> Void
    public let onNext: (() -> Void)?
    public let onMenu: () -> Void

    public init(mission: Mission, success: Bool, failureReason: String?, score: Int,
                onRetry: @escaping () -> Void, onNext: (() -> Void)?, onMenu: @escaping () -> Void) {
        self.mission = mission
        self.success = success
        self.failureReason = failureReason
        self.score = score
        self.onRetry = onRetry
        self.onNext = onNext
        self.onMenu = onMenu
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text(success ? "Delivery complete" : "Mission failed")
                .font(.largeTitle.bold())
                .foregroundStyle(success ? .green : .red)

            if !success, let reason = failureReason {
                Text(reason).multilineTextAlignment(.center).padding()
            }

            if success {
                Text("Score: \(score)").font(.title2)
            }

            HStack {
                Button("Menu", action: onMenu)
                Button("Retry", action: onRetry).buttonStyle(.bordered)
                if let onNext {
                    Button("Next", action: onNext).buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}
```

- [ ] **Step 5: Verify Previews render**

Open each new view, check the Preview canvas. Expected: each renders without crashing.

- [ ] **Step 6: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- MainMenuView, BriefingView (with SectionalMap Canvas), DebriefView.
```

```bash
git add -A
git commit -m "Add MainMenu, Briefing, Debrief views"
```

---

## Task 13: PauseView and ControlsHelpView

**Goal:** Two modal overlays.

**Files:**
- Create: `DroneDelivery/UI/PauseView.swift`
- Create: `DroneDelivery/UI/ControlsHelpView.swift`

**Interfaces produced:**
- `struct PauseView: View { let onResume, onRestart, onBriefing, onHelp, onQuit: () -> Void }`
- `struct ControlsHelpView: View { let onClose: () -> Void }`

- [ ] **Step 1: Create `UI/PauseView.swift`**

```swift
import SwiftUI

public struct PauseView: View {
    public let onResume, onRestart, onBriefing, onHelp, onQuit: () -> Void

    public init(onResume: @escaping () -> Void,
                onRestart: @escaping () -> Void,
                onBriefing: @escaping () -> Void,
                onHelp: @escaping () -> Void,
                onQuit: @escaping () -> Void) {
        self.onResume = onResume
        self.onRestart = onRestart
        self.onBriefing = onBriefing
        self.onHelp = onHelp
        self.onQuit = onQuit
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Paused").font(.title.bold()).foregroundStyle(.white)
                Button("Resume", action: onResume).buttonStyle(.borderedProminent)
                Button("Restart mission", action: onRestart)
                Button("Open briefing", action: onBriefing)
                Button("Controls help", action: onHelp)
                Button("Quit to menu", action: onQuit).tint(.red)
            }
            .padding(28)
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
        }
    }
}
```

- [ ] **Step 2: Create `UI/ControlsHelpView.swift`**

```swift
import SwiftUI

public struct ControlsHelpView: View {
    public let onClose: () -> Void

    public init(onClose: @escaping () -> Void) { self.onClose = onClose }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Controls").font(.largeTitle.bold())

                Group {
                    item("Left thumbstick", "Move horizontally (push = forward, sides = strafe).")
                    item("Right thumbstick — up/down", "Climb or descend.")
                    item("Right thumbstick — left/right", "Reserved (yaw lands in Phase 2).")
                    item("HUD chips", "Top strip: altitude AGL, current airspace class, battery %, wind.")
                    item("Pause button", "Top right of HUD. Game time freezes.")
                    item("? button", "Reopens this help screen.")
                }

                Button("Close", action: onClose).buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func item(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.headline)
            Text(body).foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 3: Verify Previews render**

⌥⌘↩ in each file. Expected: no crashes.

- [ ] **Step 4: Update CHANGELOG and commit**

`CHANGELOG.md` → `### Added`:

```
- PauseView (modal) and ControlsHelpView.
```

```bash
git add -A
git commit -m "Add Pause and ControlsHelp views"
```

---

## Task 14: RootView and final wiring

**Goal:** One `RootView` switches on `AppState.phase` to show the right surface. PauseView and ControlsHelpView are overlays on top of the flying state. App entry point is restored to the real flow. **End of Phase 1.**

**Files:**
- Modify: `DroneDelivery/App/DroneDeliveryApp.swift`
- Create: `DroneDelivery/App/RootView.swift`

**Interfaces produced:**
- `struct RootView: View { @Bindable var state: AppState; @Bindable var input: FlightInput; let store: MissionStore }`

- [ ] **Step 1: Create `App/RootView.swift`**

```swift
import SwiftUI

public struct RootView: View {
    @Bindable public var state: AppState
    @Bindable public var input: FlightInput
    public let store: MissionStore
    @State private var showHelp = false

    public init(state: AppState, input: FlightInput, store: MissionStore) {
        self.state = state
        self.input = input
        self.store = store
    }

    public var body: some View {
        ZStack {
            switch state.phase {
            case .menu:
                MainMenuView(store: store) { mission in
                    state.reset(for: mission)
                }
            case .briefing, .preflight:
                if let m = state.currentMission {
                    BriefingView(mission: m, zones: store.zones) {
                        state.phase = .flying
                    }
                }
            case .flying, .delivering, .returning:
                if let m = state.currentMission {
                    ZStack {
                        CityScene(state: state, input: input, mission: m, zones: store.zones)
                        HUDView(state: state, input: input, weather: m.conditions.weather,
                                zones: store.zones,
                                onPause: { state.paused = true },
                                onHelp: { showHelp = true })
                    }
                }
            case .debrief:
                if let m = state.currentMission {
                    let success = state.failureReason == nil
                    DebriefView(
                        mission: m,
                        success: success,
                        failureReason: state.failureReason,
                        score: state.score,
                        onRetry: { state.reset(for: m); state.phase = .flying },
                        onNext: nextMission(after: m).map { next in
                            { state.reset(for: next); state.phase = .briefing }
                        },
                        onMenu: { state.phase = .menu }
                    )
                    .onAppear {
                        if success {
                            state.score = Int(state.batteryPercent * 10)
                            store.complete(id: m.id, score: state.score)
                        }
                    }
                }
            }

            if state.paused {
                PauseView(
                    onResume: { state.paused = false },
                    onRestart: {
                        if let m = state.currentMission {
                            state.reset(for: m); state.phase = .flying
                        }
                    },
                    onBriefing: { state.paused = false; state.phase = .briefing },
                    onHelp: { showHelp = true },
                    onQuit: { state.paused = false; state.phase = .menu }
                )
            }

            if showHelp {
                ControlsHelpView { showHelp = false }
                    .background(.regularMaterial)
            }
        }
    }

    private func nextMission(after current: Mission) -> Mission? {
        guard let idx = store.all.firstIndex(where: { $0.id == current.id }) else { return nil }
        let nextIdx = idx + 1
        return nextIdx < store.all.count ? store.all[nextIdx] : nil
    }
}
```

- [ ] **Step 2: Replace `App/DroneDeliveryApp.swift` with the final entry**

```swift
import SwiftUI

@main
struct DroneDeliveryApp: App {
    @State private var store = MissionStore()
    @State private var state = AppState()
    @State private var input = FlightInput()

    var body: some Scene {
        WindowGroup {
            RootView(state: state, input: input, store: store)
        }
    }
}
```

- [ ] **Step 3: Run on simulator end-to-end**

⌘R, iPhone 15 simulator. Walk the full loop:

1. Main menu shows three missions. m02 and m03 are locked.
2. Tap m01 → Briefing renders with sectional map (green G zone), no NOTAMs, weather card.
3. Tap "Go fly" → city scene + HUD + thumbsticks. Drone hovers above pickup.
4. Fly to the orange dropoff pole. (Currently delivery isn't auto-detected — see Step 4 below for the manual trigger.)
5. **Manual delivery trigger:** for Phase 1, deliver = land within 5 m of dropoff. This is enforced inside `CityScene` — see Step 4.

- [ ] **Step 4: Add delivery success detection in `CityScene`**

In `Scenes/City/CityScene.swift`, extend `evaluateFailures` into a combined `evaluateOutcome` that also checks for success. Add at the bottom of the function, before the `for entity in content.entities…NOTAM` block:

```swift
// Success: drone within 5 m of dropoff and below 3 m altitude.
for entity in content.entities where entity.components.has(KinematicComponent.self) {
    let p = SIMD2<Float>(entity.position.x, entity.position.z)
    let target = SIMD2<Float>(mission.dropoff.position.x, mission.dropoff.position.z)
    if simd_distance(p, target) < 5, entity.position.y < 3 {
        state.failureReason = nil
        state.phase = .debrief
        return
    }
}
```

Rebuild, re-run, and confirm: landing near the orange pole transitions to the Debrief screen with "Delivery complete."

- [ ] **Step 5: Verify failure paths**

1. From menu → m01 → fly straight up → expect Debrief with "Altitude bust" message.
2. From menu → m01 → hover until battery hits 0 → expect Debrief with battery message.
3. From menu → m01 (complete it) → menu now shows m02 unlocked.

- [ ] **Step 6: Run the full test suite**

⌘U. Expected: all tests pass (polygon, save round-trip, mission store, kinematic math).

- [ ] **Step 7: `/simplify` the working tree**

In the Claude Code chat: invoke `/simplify`. Address any findings.

- [ ] **Step 8: Update CHANGELOG and commit**

`CHANGELOG.md`:

```
### Added
- RootView phase switch wiring all surfaces together.
- Delivery success detection (landing within 5 m of dropoff).

### Notes
- Phase 1 complete: three missions, full briefing → flying → debrief loop, diegetic
  Part 107 enforcement (400 ft AGL, battery, airspace, NOTAM), wind affects flight.
```

```bash
git add -A
git commit -m "Wire RootView and complete Phase 1 loop"
git push
```

---

## Phase 1 done

Definition of done for Phase 1, all of which Task 14 confirms:

- App builds clean with Swift 6 strict concurrency.
- Three missions in `Missions.json` (calm pizza, crosswind grocery, Class B + NOTAM video).
- Full UI flow: menu → briefing (with sectional map) → flying (with HUD + sticks + pause) → debrief.
- Diegetic enforcement: 400 ft AGL, battery zero, unauthorized airspace, active NOTAM, collision.
- Wind affects flight; other weather is shown in briefing.
- Progress persists via `UserDefaults`.
- All Swift Testing tests pass.

When you're ready for Phase 2, the next plan (`docs/superpowers/plans/<date>-phase2-gameplaykit.md`) will:

- Replace the enum + switch state flow with `GKStateMachine`.
- Add `GKRandomSource` weather variation.
- Add ceiling/visibility/density-altitude effects on flight.
- Add gyro tilt (toggleable from a real Settings screen).
- Expand to 5–10 missions.
