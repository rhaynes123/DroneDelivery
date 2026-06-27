# CLAUDE.md

Guidance for Claude working in this repo. Read this every session before touching code.

## What this project is

A focused mini-game (5–10 missions, ~2–4 weeks of evenings) where the user pilots a delivery drone around one small persistent map. The user is **learning Swift + RealityKit for the first time** AND **studying for the FAA Part 107 commercial UAS license**. The game must serve both goals.

**Part 107 rules are the mechanics**, not a separate quiz layer. Briefings show real sectional charts / METARs / NOTAMs. The flight model enforces 400 ft AGL, no-fly zones, weather effects, battery limits. The lesson IS the gameplay.

## Grounding — do NOT invent regulations

Read [`REFERENCES.md`](./REFERENCES.md) before encoding any rule, weather minimum, altitude limit, or airspace requirement. Cite the section number in a code comment where the rule is enforced. If you can't recall the exact rule, **web-fetch the source** — do not guess. Part 107 changes (Remote ID, night ops, ops over people have all changed in recent years). The references file tells you where to look; the live FAA source is the truth.

## Locked design decisions

These are settled. Do not relitigate without explicit user instruction.

| Area | Decision |
|---|---|
| Platform | iPhone / iPad (iOS + iPadOS 18+, Swift 6) |
| Stack | SwiftUI + RealityKit (Reality Composer Pro scene) |
| Camera | Third-person chase cam |
| Flight model | Arcade kinematic (custom Component + System, no PhysicsBody) |
| World | One persistent small map |
| Variety axes | Weather, airspace/NOTAMs, battery — NOT per-cargo mechanics |
| Cargo | Pizza/groceries/video etc. are **theme only**, same core verb |
| Part 107 | Diegetic — rules enforced in-game, not quizzed |

## Phasing — do not jump ahead

Each phase ships a runnable build. Do not introduce a later-phase framework during an earlier phase.

- **Phase 1:** Pure RealityKit + SwiftUI + `UserDefaults`. Core loop end-to-end.
- **Phase 2:** Add GameplayKit (`GKStateMachine` for mission flow, `GKRandomSource` for weather).
- **Phase 3:** Add SwiftData pilot logbook. CloudKit sync optional after that.

If you find yourself reaching for GameplayKit in Phase 1, stop. That's a Phase 2 problem.

## How to write code here

**Invoke `/ponytail:ponytail` at the start of every coding session.** It enforces the rules below. If it's already active, good — keep it on.

**Run `/simplify` (or `/code-review --fix`) on the diff before declaring any change done.** Treat it as part of the build, not optional.

The ladder, in order — stop at the first rung that holds:

1. **Does this need to exist at all?** If speculative, skip it.
2. **Already in this codebase?** Reuse it.
3. **Apple framework does it?** Use SwiftUI / RealityKit / Foundation / GameplayKit (Phase 2+) / SwiftData (Phase 3+) before writing your own.
4. **Native platform feature?** `@Observable`, `UserDefaults`, `Codable`, `CoreHaptics`, `CoreMotion` — use them.
5. **Already-installed dependency solves it?** Use it. Never add a new SPM dependency for what 20 lines can do.
6. **One line?** One line.
7. **Only then:** the minimum code that works.

### Hard rules

- No third-party SPM dependencies without explicit user approval. Apple's frameworks cover this game.
- No interface with one implementation. No factory for one product. No protocol for a struct only used once.
- No `// TODO: maybe later` scaffolding. Later can scaffold for itself.
- No comments explaining *what* code does — the names should. Comments only for non-obvious *why* (a Part 107 quirk, a RealityKit gotcha, a physics simplification).
- Mark deliberate simplifications with a `// ponytail:` comment naming the ceiling and upgrade path. Example: `// ponytail: 1 km wind grid, refine if missions need local gusts`.
- Shortest working diff wins — but only after you understand the change. Read the relevant files first, then climb the ladder.

### When NOT to be lazy

- Input validation at trust boundaries (mission JSON, save files).
- Anything the user explicitly requested.
- Physical realism knobs that need tuning — leave a calibration constant, not just a hard-coded number. Drones, wind, batteries are real things; minimal models can't see edge cases.
- Non-trivial logic gets ONE runnable self-check (an `assert`-based `#Preview` or a tiny `#expect` test). No framework sprawl.

## Xcode project workflow (XcodeGen)

The `.xcodeproj` is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Source of truth = `project.yml`. After adding any new source file or resource on disk, run:

```bash
xcodegen generate
```

If you don't, Xcode won't see the new file. Don't hand-edit `pbxproj`. If the project file feels wrong, fix `project.yml` and regenerate.

Install: `brew install xcodegen`. The generated `.xcodeproj` is committed for simpler onboarding, but `project.yml` is what changes intentionally.

## Folder layout (don't deviate without reason)

```
DroneDelivery/
├── App/           DroneDeliveryApp + AppState (@Observable)
├── Scenes/City/   RealityView wrapper + City.usda
├── Drone/         Entity factory, Components, System
├── Flight/        Input (touch + gyro), Wind
├── Mission/       Models, Store, Missions.json
├── Airspace/      Zones + RealityKit overlays
├── Weather/       Models + effect applicators
├── UI/            SwiftUI screens (Menu, Briefing, HUD, Debrief)
└── Persistence/   UserDefaults wrapper (Phase 1)
```

One folder = one bounded responsibility. UI never touches entities directly — it reads `AppState`, which the System writes each frame.

## Before claiming "done"

1. Build succeeds with no warnings.
2. The change actually runs on a simulator or device (or you say explicitly you couldn't test it).
3. `/simplify` reviewed the diff.
4. Non-trivial logic has its self-check.

Evidence before assertions. Always.
