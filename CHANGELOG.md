# Changelog

All notable changes to DroneDelivery. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); dates in `YYYY-MM-DD`.

Update this file in the same commit as the change. One entry per release, grouped under: **Added**, **Changed**, **Deprecated**, **Removed**, **Fixed**, **Security**. Unreleased work lives under `## [Unreleased]`.

## [Unreleased]

### Added
- `CLAUDE.md` — project guidance, locked design decisions, phasing rules, ponytail/simplify discipline.
- `CONTRIBUTING.md` — setup, code style, phase discipline, self-review checklist.
- `REFERENCES.md` — authoritative FAA / Part 107 sources to cite rather than invent.
- `CHANGELOG.md` — this file.
- Design doc at `docs/superpowers/specs/2026-06-26-drone-delivery-design.md`.
- Phase 1 implementation plan at `docs/superpowers/plans/2026-06-27-phase1-core-loop.md` (14 tasks, TDD where the math allows).
- `project.yml` + XcodeGen-generated `DroneDelivery.xcodeproj` (iOS 18, Swift 6 strict concurrency).
- Placeholder `DroneDeliveryApp.swift` and `BootstrapTests.swift`.
- Domain model types: Mission, Conditions, Waypoint, WeatherSpec, AirspaceZone (with polygon containment), NOTAM, GamePhase.
- PhysicsTuning constants (Flight/PhysicsTuning.swift) — all calibration knobs in one place.
- SaveData + SaveStore: UserDefaults-backed Codable persistence with round-trip test.
- Three Phase 1 missions (Missions.json) + airspace zones (Airspace.json).
- MissionStore (@Observable): loads bundle, tracks unlocked/completed, persists via SaveStore.
- RealityKit components (Kinematic, Battery, Altimeter, Wind, Cargo) + registration.
- KinematicSystem with per-frame velocity smoothing, wind transfer, altitude, battery drain.
- KinematicMath helpers with tests.
