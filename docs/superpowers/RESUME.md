# Resume DroneDelivery Phase 1

Paste the prompt at the bottom of this file into a new Claude Code session to pick up exactly where we left off.

---

## State snapshot (as of 2026-06-27)

- **Project:** `/Users/richardhaynes/Developer/Projects/Swift/DroneDelivery`
- **Branch / remote:** `main` → `https://github.com/rhaynes123/DroneDelivery`
- **Plan:** `docs/superpowers/plans/2026-06-27-phase1-core-loop.md` (14 tasks)
- **Spec:** `docs/superpowers/specs/2026-06-26-drone-delivery-design.md`
- **Progress ledger:** `.superpowers/sdd/progress.md` (gitignored — the durable record of which tasks are DONE)
- **Workflow:** Subagent-Driven Development (`superpowers:subagent-driven-development`)

### Completed (8 of 14)

- Task 1 — Xcode project (replaced by XcodeGen — `project.yml` is source of truth)
- Task 2 — Domain models
- Task 3 — PhysicsTuning constants
- Task 4 — SaveData + UserDefaults
- Task 5 — Mission catalog + MissionStore
- Task 6 — RealityKit components + KinematicSystem
- Task 7 — AppState
- Task 8 — FlightInput + Thumbstick (review clean after one-line ponytail-comment fix)

### Pending visual check from the user

Thumbstick `#Preview` canvas (Task 8). Quick check: open `DroneDelivery/Flight/Thumbstick.swift` in Xcode → `⌥⌘↩` for Preview → drag the inner knob, it should clamp to the radius and spring back on release.

### Up next

- Task 9 — Drone + city factories (`makeDrone()`, `makeCity()`)
- Task 10 — CityScene RealityView wrapper (**first runnable flight** — pause here for full simulator verification, per the user's batched-visual-check preference)
- Task 11 — HUDView (pause for visual)
- Task 12 — MainMenu + Briefing + Debrief (pause for visual)
- Task 13 — Pause + ControlsHelp (pause for visual)
- Task 14 — RootView wiring + delivery success (pause for end-to-end simulator)
- Final whole-branch code review

## Workflow reminders

- **Per task:** generate brief → dispatch implementer subagent → generate review-package → dispatch task reviewer → fix loop if needed → update `.superpowers/sdd/progress.md`.
- Helper scripts live at `/Users/richardhaynes/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.3/skills/subagent-driven-development/scripts/`.
  - `task-brief PLAN_FILE N` → writes `.superpowers/sdd/task-N-brief.md`
  - `review-package BASE HEAD` → writes the diff file the task reviewer reads
- BASE for the next task = current `HEAD`. Record it before dispatching the implementer; never use `HEAD~1` (it silently truncates multi-commit tasks).
- Model selection: cheap tier (haiku) for verbatim transcription tasks; standard tier (sonnet) for multi-file or integration work. Always specify the model explicitly when dispatching.
- Verification command:
  ```bash
  xcodebuild -scheme DroneDelivery \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    build test
  ```
- `xcodegen generate` must run after any file added/removed on disk, before `xcodebuild`.

## Environment requirements (already in place last time)

- Xcode 26.6 with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` already set
- `xcodegen` installed via Homebrew
- GitHub CLI logged in as `rhaynes123` with `repo` scope

## Resume prompt — paste this into the new session

```
Pick up Phase 1 of DroneDelivery where we left off. Read these in order before doing anything:

1. /Users/richardhaynes/Developer/Projects/Swift/DroneDelivery/docs/superpowers/RESUME.md
2. /Users/richardhaynes/Developer/Projects/Swift/DroneDelivery/.superpowers/sdd/progress.md
3. /Users/richardhaynes/Developer/Projects/Swift/DroneDelivery/CLAUDE.md
4. /Users/richardhaynes/Developer/Projects/Swift/DroneDelivery/docs/superpowers/plans/2026-06-27-phase1-core-loop.md (skim — full content for each task lives in the per-task brief files)

Then:

- Invoke the `superpowers:subagent-driven-development` skill via the Skill tool to load the SDD workflow.
- Check `git log --oneline -15` and the progress ledger to confirm what's already done — never re-dispatch a task the ledger marks complete.
- Ask me if I've finished the pending Thumbstick #Preview visual check (Task 8). Don't proceed to Task 9 until I confirm or wave it off.
- When clear, dispatch the Task 9 implementer (haiku model, brief at `.superpowers/sdd/task-9-brief.md` — generate it if missing via the `task-brief` script).
- Keep the same batched-visual-check rhythm: pause after Tasks 10/11/12/13/14 for me to verify in the simulator.

Use ponytail mode (already active via session start). Run /simplify on diffs before declaring a task done. Cite CFR sections in code for any encoded regulation.
```

---

*This file is committed to the repo so it survives sessions. The actual SDD progress ledger at `.superpowers/sdd/progress.md` is git-ignored — recover it from `git log` if it's ever lost.*
