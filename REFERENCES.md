# References

Authoritative sources for the Part 107 / sUAS rules the game enforces. **Cite these, do not invent.** Before encoding any rule numerically (altitude limits, weather minima, separation requirements), web-fetch the current text — regulations change.

Last verified: 2026-06-26.

## Primary regulation

| ID | Title | Where |
|---|---|---|
| **14 CFR Part 107** | Small Unmanned Aircraft Systems | `ecfr.gov` — search "14 CFR Part 107" |
| **14 CFR Part 89** | Remote Identification of Unmanned Aircraft | `ecfr.gov` — search "14 CFR Part 89" |
| **AIM** | Aeronautical Information Manual (airspace, operations, weather) | `faa.gov` — search "Aeronautical Information Manual" |

Part 107 is the law. Part 89 covers Remote ID (now in effect). The AIM is the operational reference for airspace and procedures — much of what's testable on the Part 107 exam draws from it.

## FAA study materials (test-aligned)

| ID | Title | Why it matters |
|---|---|---|
| **FAA-S-ACS-10** | Remote Pilot — Small Unmanned Aircraft Systems Airman Certification Standards | The test blueprint. Every knowledge area on the exam is enumerated here. |
| **FAA-G-8082-22** | Remote Pilot — Small Unmanned Aircraft Systems Study Guide | Plain-language companion to Part 107. |
| **AC 107-2** | Advisory Circular: Small Unmanned Aircraft Systems (sUAS) | "How to comply" guidance, examples, recommended practices. |
| **Aeronautical Chart Users' Guide** | Sectional chart symbology decoder | For briefing-screen chart reading. |
| **FAA-H-8083-28** | Aviation Weather Handbook | METAR/TAF decoding, density altitude, ceiling/visibility, wind shear. |

Hub: `faa.gov/uas` (the FAA's drone portal — find each doc from there).

## Operational tools (referenced in-game)

| Tool | What it is |
|---|---|
| **B4UFLY** | FAA-approved app for checking where you can fly. The briefing UI should *feel* like this. |
| **LAANC** | Low Altitude Authorization and Notification Capability. Auto-approval for flying in controlled airspace near participating airports. |
| **DroneZone** | `faa.gov/uas` registration + waiver portal. |
| **NOTAMs / TFRs** | Notices to Air Missions and Temporary Flight Restrictions. Sourced from FAA NOTAM system. |

## How to use these references

**When writing a mission, briefing screen, or rule-enforcement code:**

1. Identify which rule the mechanic encodes (e.g., "max 400 ft AGL" → 14 CFR § 107.51(b)).
2. Web-fetch the current text of that section. Do not rely on memory.
3. Cite the section in a code comment where the rule is encoded:
   ```swift
   // 14 CFR § 107.51(b): max 400 ft AGL unless within 400 ft of a structure
   static let maxAltitudeAGL: Float = 400
   ```
4. If the rule changed since this file's "Last verified" date, update the file and the comment.

**When the player encounters the rule in-game:**

The briefing or debrief should cite the rule by section number ("Altitude bust — see 14 CFR § 107.51"). This trains the player to look at the actual regulation, not just trust the game.

## What is NOT in this file (intentionally)

- Memorized rule numbers. Those go in code with citations. This file points you to where to verify them.
- Deep URLs. They rot. Document numbers and titles don't.
- Third-party study sites (Pilot Institute, King Schools, etc.). They're fine supplements but not authoritative — only the FAA is.
