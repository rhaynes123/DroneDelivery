# Contributing

This is a personal learning project. Contributors = the user + Claude. Rules below keep us honest.

## Project setup

- **Xcode** 16 or later (point CLI at it once: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`)
- **iOS / iPadOS** 18+ deployment target
- **Swift** 6 (strict concurrency on)
- **XcodeGen** (`brew install xcodegen`) — generates `.xcodeproj` from `project.yml`. Run `xcodegen generate` after adding files on disk.
- No runtime package manager dependencies. Apple frameworks only unless the user explicitly approves an addition. (XcodeGen is a dev tool, not a runtime dep.)

Open `DroneDelivery.xcodeproj`, pick an iPhone/iPad simulator, run.

## Philosophy

We optimize for two things:
1. The user learning Swift and RealityKit.
2. The user passing the FAA Part 107 exam.

Anything that doesn't serve one of those is cut. No "nice to haves" for hypothetical future requirements.

## Lazy by default

Read `CLAUDE.md` for the full rules. The short version:

- Reach for an Apple framework before writing your own.
- One line beats fifty. Stdlib beats a helper. A struct beats an interface.
- The shortest *correct* diff wins. Smallest change in the wrong place is two bugs, not zero.
- Deletion over addition. Boring over clever.
- Mark deliberate shortcuts with `// ponytail:` and name the upgrade path.

When in doubt, run `/ponytail:ponytail` and try again.

## Phase discipline

- **Phase 1:** SwiftUI + RealityKit + UserDefaults only.
- **Phase 2:** GameplayKit added (state machine + random).
- **Phase 3:** SwiftData logbook added.

Do not pull a later-phase tool into an earlier phase. If you feel the pain of not having it, that's the signal — finish the current phase first.

## Code style

- Swift 6 strict concurrency. No `@unchecked Sendable` without a one-line justification.
- `@Observable` for view-driving state. No Combine unless an Apple API forces it.
- Components are plain structs conforming to `Component`. Systems own the mutation logic.
- SwiftUI views are dumb: read `AppState`, render. No game logic in views.
- Names over comments. Comments only for non-obvious *why*.
- One folder = one bounded responsibility. Files over ~150 lines are a signal, not a target.

## Reviewing your own work

Before claiming a change is done:

1. **Build with no warnings.** Treat warnings as errors during dev.
2. **Run it.** Either on a simulator/device, or state plainly you couldn't.
3. **`/simplify` the diff.** This is not optional — it catches the over-engineering ponytail mode is supposed to prevent. Equivalent to `/code-review --fix`.
4. **Non-trivial logic has a self-check.** One assert-based `#Preview`, one `#expect` test, or one runnable demo. No frameworks, no fixtures.

If you can't verify it works, say so. Don't pretend.

## Commit style

- One logical change per commit.
- Subject line ≤ 70 chars, imperative ("Add wind effect to KinematicSystem").
- Body explains *why*, not what.
- **Update `CHANGELOG.md`** in the same commit as any user-visible or design-affecting change. Entry under `## [Unreleased]`, grouped by Added / Changed / Deprecated / Removed / Fixed / Security.

## When the user says "stop ponytail" or "normal mode"

Honor it. Their codebase, their call. The rules here are defaults, not laws.
