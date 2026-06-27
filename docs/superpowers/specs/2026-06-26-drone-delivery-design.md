# DroneDelivery — Design Spec

**Date:** 2026-06-26
**Status:** Draft for user review
**Author:** Brainstormed with Claude

## Goals

Two goals served simultaneously by one project. Every design choice trades against both:

1. **Learn Swift and RealityKit** end-to-end from a first-time start.
2. **Study for the FAA Part 107** Remote Pilot (commercial sUAS) knowledge test.

Success looks like: a runnable iPhone/iPad app where the player flies a delivery drone through 5–10 missions, each of which exercises a real Part 107 concept (airspace, weather, NOTAMs, battery management). The user finishes the build with working Swift/RealityKit fluency and meaningful exposure to the test material.

## Non-goals

- Realistic per-rotor flight simulation.
- Multiplayer / online services.
- Multiple environments / open world.
- Per-cargo gameplay mechanics (cargo is theme only).
- Anything beyond iOS/iPadOS in v1.

## Locked decisions

| Area | Decision |
|---|---|
| Scope | Focused mini-game, 5–10 missions, ~2–4 weeks of evenings |
| Platform | iPhone + iPad, iOS/iPadOS 18+, Swift 6 strict concurrency |
| Stack | SwiftUI + RealityKit, Reality Composer Pro for the scene |
| Camera | Third-person chase cam |
| Flight model | Arcade kinematic (custom Component + System, no `PhysicsBody`) |
| World | One persistent small map |
| Variety axes | Weather, airspace/NOTAMs, battery — NOT per-cargo mechanics |
| Cargo | Pizza / groceries / video etc. are **theme only**, same core verb |
| Part 107 integration | Diegetic — rules enforced in-game, not quizzed |
| Persistence (Phase 1) | `UserDefaults` for one `Codable` `SaveData` struct |

## Phasing

Each phase ships a runnable build. Do not pull a later-phase framework into an earlier phase.

- **Phase 1 — Core loop.** SwiftUI + RealityKit + `UserDefaults`. Three missions, full briefing → flying → debrief loop, one weather scenario, basic airspace + NOTAM, battery + 400 ft AGL ceiling enforced. Ship-able as "I built a Swift game."
- **Phase 2 — Add GameplayKit.** Refactor mission state flow to `GKStateMachine`. Use `GKRandomSource` for procedural weather variation between runs of the same mission. Expand to 5–10 missions.
- **Phase 3 — Add SwiftData logbook.** Persist a per-flight record (date, mission, weather encountered, airspace traversed, score, failure cause if any). New `LogbookView`. CloudKit sync optional after that.

## Architecture

### Module layout

One iOS app target, one Reality Composer Pro package, organized by domain:

```
DroneDelivery/
├── App/                  DroneDeliveryApp.swift, AppState (@Observable), RootView
├── Scenes/City/          CityScene wrapper around RealityView, City.usda
├── Drone/                makeDrone() factory, Kinematic / Battery / Altimeter / Cargo Components, KinematicSystem
├── Flight/               FlightInput (touch + gyro), WindComponent, PhysicsTuning constants
├── Mission/              Mission model, MissionStore (@Observable), Missions.json
├── Airspace/             AirspaceZone model, AirspaceOverlay (2D briefing + 3D world entities)
├── Weather/              Weather model, WeatherEffects applicator
├── UI/                   MainMenuView, BriefingView, HUDView, DebriefView, PauseView, ControlsHelpView
└── Persistence/          SaveData (Codable) + UserDefaults wrapper
```

Phase 2 adds `GameplayKit/` (MissionStateMachine, WeatherRoller). Phase 3 adds `Logbook/` (SwiftData `@Model` + LogbookView).

Each folder = one bounded responsibility. UI never touches RealityKit entities directly — it reads `AppState`, which the Systems write each frame.

### State ownership

- **`AppState` (`@Observable`)** — root truth for view-driving data: current `phase` (game flow enum), `currentMission`, `currentAirspace`, `batteryRemainingWh`, `altitudeAGL`, `paused`. Lives for the app lifetime.
- **`MissionStore` (`@Observable`)** — owns mission catalog + progress. Loads `Missions.json` on launch; reads/writes `UserDefaults`.
- **RealityKit Entities + Components** — live in the scene; mutated only by Systems. View layer reads via mirror values on `AppState`.

### Drone — RealityKit ECS

Drone is built by a factory function, not a subclass:

```swift
func makeDrone() -> Entity
```

Components (plain structs conforming to `Component`):

- **`KinematicComponent`** — `velocity: SIMD3<Float>`, `targetVelocity: SIMD3<Float>`, `maxSpeed: Float`. Arcade smoothing lerps velocity toward target.
- **`BatteryComponent`** — `capacityWh: Double`, `remainingWh: Double`, `baseDrainW`, `hoverDrainW`. Drained by the System each frame as `baseDrainW + speedDrain(v) + windFightDrain(wind, v)`.
- **`AltimeterComponent`** — `agl: Float`. Updated by raycasting straight down to terrain from the drone's position.
- **`CargoComponent`** — `kind: CargoKind` (`.pizza`, `.groceries`, `.video`, …), `delivered: Bool`. Theme/UI only; does not affect physics in v1.

`KinematicSystem` subscribes to `SceneEvents.Update` and is the only mutator. Each frame it:

1. Reads `FlightInput` (touch sticks + optional gyro tilt).
2. Reads `Weather.wind` and applies the wind vector to drone velocity.
3. Integrates velocity into position; writes the entity transform.
4. Drains battery according to the formula above.
5. Updates `AltimeterComponent.agl` from terrain raycast.
6. Determines current airspace zone (point-in-polygon over `AirspaceZone` set) and updates `AppState.currentAirspace`.
7. Mirrors display values (battery %, altitude AGL, airspace) into `AppState` for the HUD.

### Missions

Mission = a JSON record + a generated runtime state. No subclasses, no factories.

```swift
struct Mission: Codable, Identifiable {
    let id: String                 // e.g. "m01_pizza_suburb"
    let cargoTheme: CargoKind      // display only
    let pickup: Waypoint           // scene-space coords
    let dropoff: Waypoint
    let conditions: Conditions
    let unlockAfter: String?       // mission id, nil for first
}

struct Conditions: Codable {
    let weather: WeatherSpec       // wind kts/dir, ceiling ft, vis sm, temp, density alt
    let airspace: [AirspaceRef]    // active zones + NOTAMs for this mission
    let batteryWh: Double          // budget for this mission
    let timeOfDay: TimeOfDay       // .day / .dusk / .night
}
```

`Missions.json` ships with the app. `MissionStore` loads on launch, exposes `current`, `unlocked: Set<String>`, `complete(id:score:)`. Progress = `Set<String>` of completed IDs in `UserDefaults`.

**Mission flow** (Phase 1 = `enum` + switch; Phase 2 = `GKStateMachine`):

```
.menu → .briefing → .preflightCheck → .flying → .delivering → .returning → .debrief → .menu
```

**Failure conditions** (mission ends, debrief shows what failed):

- Battery reaches 0 → drone freezes in place; mission fails immediately (no falling-and-crashing animation in v1).
- Altitude exceeds 400 ft AGL (14 CFR § 107.51(b) bust) → mission fails on bust, not on approach.
- Entered an active no-fly zone or TFR without authorization → mission fails on entry.
- Collided with terrain or a building → detected via RealityKit `CollisionComponent` on the drone and scene geometry (collision events without `PhysicsBody`); mission fails on first contact.
- Cargo destination not reached before battery depletion → covered by the battery-zero rule above.

### Part 107 systems

All four are diegetic — the rule **is** the mechanic. Each system reads `AppState` / components and writes one specific output.

**Airspace** — `AirspaceZone(class, polygon, floorAGL, ceilingAGL, requiresAuthorization)`. Rendered two ways: 2D colored polygons on the briefing's sectional-style map, and 3D translucent volumes in the world via `ModelEntity` with an unlit material. `KinematicSystem` queries current zone each frame.

**Weather** — `Weather(wind, visibilitySM, ceilingFtAGL, temperature, densityAltitudeFt)`. Effects:

- Wind: constant vector added to drone velocity (via `WindComponent`).
- Low ceiling: fog effect via RealityKit `EnvironmentResource`; exceeding ceiling fails the mission ("lost VLOS").
- Density altitude: reduces max thrust → lower max climb rate and top speed.

The briefing shows the METAR in raw form and decoded — a Part 107 test question literally asks you to decode METARs.

**NOTAMs / TFRs** — same shape as `AirspaceZone`, with a time window and a reason string. Render red in briefing and world. Active NOTAMs are treated as unauthorized zones.

**Battery** — `BatteryComponent` drains by `baseDrainW + speedDrain(v) + windFightDrain(wind, v)`. The HUD shows %, remaining minutes, and a return-to-home reserve marker. Density altitude amplifies drain. Hovering costs nearly as much as cruising (true of real quads).

**Calibration knobs** — wind→drift coefficient, density-altitude→thrust curve, base/speed/hover drain ratios — all live as named constants in `Flight/PhysicsTuning.swift`. Each carries a `// ponytail:` comment naming the ceiling and upgrade path. Real quads need tuning; a minimal model can't see the right numbers without it.

### Grounding policy for regulations

Before encoding any altitude limit, weather minimum, separation requirement, or airspace rule:

1. Identify the relevant CFR / AIM section.
2. Web-fetch its current text — do not rely on memory.
3. Cite the section in a code comment where the rule is enforced.

`REFERENCES.md` at the repo root lists the authoritative sources (14 CFR Part 107, Part 89, AC 107-2, FAA-S-ACS-10, FAA-G-8082-22, AC, Aeronautical Chart Users' Guide, FAA-H-8083-28, AIM, plus operational tools B4UFLY, LAANC, DroneZone). Regulations change; this is the durable pointer.

### UI

Six SwiftUI surfaces driven by `AppState.phase` from one `switch` in `RootView`. Pause and ControlsHelp are modal overlays on top of the active state.

- **MainMenuView** — mission list with lock icons. Phase 3 adds a Logbook button.
- **BriefingView** — the Part 107 lesson surface. Sections: Today's flight (cargo + route on a sectional-style 2D map), Weather (raw + decoded METAR), Airspace (color-coded zones + NOTAMs/TFRs), Aircraft (battery, anti-collision lights if night, weight & balance), Limits (rules in play with CFR citations). "Go fly" button at bottom.
- **HUDView** — flight overlay. Top: altitude AGL (red near 400 ft), airspace class chip, battery %, wind. Bottom: two virtual thumbsticks. "?" reopens briefing as a scrim. Pause button.
- **DebriefView** — pass/fail with reasons, each citing the rule. Retry / Next / Menu.
- **PauseView** — overlay; freezes `KinematicSystem` via `AppState.paused`. Options: Resume, Restart, Briefing, Controls help, Quit to menu.
- **ControlsHelpView** — single scrollable card: thumbstick layout, gyro toggle, HUD chip meanings. Reachable from Pause and MainMenu.

**Sectional-style map** — drawn with `Canvas` from polygon data. No MapKit, no images.

### Persistence

Phase 1, one `Codable` struct in `UserDefaults`:

```swift
struct SaveData: Codable {
    var completedMissionIDs: Set<String>
    var bestScore: [String: Int]      // mission id → score
    var settings: Settings             // gyro on/off, units, etc.
}
```

Read on launch, write on mission complete and settings change. No migrations.

Phase 3 introduces SwiftData **for the flight logbook only**. Mission progress remains in `UserDefaults` because it doesn't need querying.

### Testing

Swift Testing (`import Testing`, `@Test`, `#expect`) — Apple's modern framework, ships with Xcode 16. No third-party deps. The ponytail rule: non-trivial logic gets ONE runnable check that fails if the logic breaks.

- `KinematicSystem` — one test: one integration step with a known input produces a known output. Same for wind drift and battery drain formulas.
- `MissionStore.load()` — one test: `Missions.json` parses to a non-empty array, and no mission's `unlockAfter` references a non-existent mission.
- `AirspaceZone.contains(point:)` — one test of polygon containment with known inside + outside points.

SwiftUI views get `#Preview` blocks; no view tests. Visual inspection is the test for a screen this small.

### Build

- Xcode 16+
- iOS / iPadOS 18+ deployment target
- Swift 6, strict concurrency on
- No SPM dependencies. Apple frameworks only.
- One scheme, one configuration during dev.
- No CI in v1. Add GitHub Actions build later if the project starts being shared.

## Data shapes — summary

```swift
// Drone
struct KinematicComponent: Component { var velocity, targetVelocity: SIMD3<Float>; let maxSpeed: Float }
struct BatteryComponent: Component { let capacityWh, baseDrainW, hoverDrainW: Double; var remainingWh: Double }
struct AltimeterComponent: Component { var agl: Float }
struct CargoComponent: Component { let kind: CargoKind; var delivered: Bool }

// Flight
struct WindComponent: Component { var vector: SIMD3<Float> }

// Mission
enum CargoKind: String, Codable { case pizza, groceries, video, clothes }
enum TimeOfDay: String, Codable { case day, dusk, night }
struct Waypoint: Codable { let position: SIMD3<Float>; let label: String }

// Airspace
enum AirspaceClass: String, Codable { case b, c, d, e, g }
struct AirspaceZone: Codable, Identifiable { let id: String; let `class`: AirspaceClass; let polygon: [SIMD2<Float>]; let floorAGL, ceilingAGL: Float; let requiresAuthorization: Bool }
struct NOTAM: Codable, Identifiable { let id: String; let polygon: [SIMD2<Float>]; let floorAGL, ceilingAGL: Float; let reason: String; let start, end: Date }

// Weather
struct Weather: Codable {
    let windKts: Float; let windDir: Float   // degrees true
    let visibilitySM: Float
    let ceilingFtAGL: Float
    let temperatureC: Float
    let densityAltitudeFt: Float
}

// Game flow
enum GamePhase { case menu, briefing, preflight, flying, delivering, returning, debrief }

// Persistence
struct SaveData: Codable { var completedMissionIDs: Set<String>; var bestScore: [String: Int]; var settings: Settings }
struct Settings: Codable { var gyroEnabled: Bool; var useImperialUnits: Bool }
```

## Open questions (for later)

- Sound design — not in v1 scope. Reconsider after Phase 1 ships.
- Haptics — `CoreHaptics` for wind buffeting and rotor feel. Phase 2 polish.
- Real sectional chart import (vector tile of an actual area) — Phase 3+.
- Replay viewer — would be a natural Phase 3 use of the SwiftData flight log.

## References

See `REFERENCES.md` at repo root. The short list:

- **14 CFR Part 107** (the regulation)
- **14 CFR Part 89** (Remote ID)
- **FAA-S-ACS-10** (Airman Certification Standards — the test blueprint)
- **FAA-G-8082-22** (Remote Pilot Study Guide)
- **AC 107-2** (Advisory Circular)
- **Aeronautical Chart Users' Guide**
- **FAA-H-8083-28** (Aviation Weather Handbook)
- **AIM** (Aeronautical Information Manual)
