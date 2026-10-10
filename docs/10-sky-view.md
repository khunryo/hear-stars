# Live sky implementation plan — 2026-10-11

> Execution: implement inline in the existing feature branch; use the approved in-chat design. Superpowers planning/TDD and Matt Pocock implementation guidance apply.

**Goal:** Follow a real star with sound/haptics, reveal its surrounding stars and original constellation lines, and keep exploring through an optional camera background.

**Spec:** User approved the 2026-10-11 proposal in chat: actual-coordinate sky, optional live camera, manual alignment against a visible named star, and a next-star action. This document records that approved design and its implementation steps.

**Architecture:** Pure ENU vector projection and a bounded, session-only rotation live in HearStarsCore. SensorService captures the camera-up vector with each direction snapshot. SwiftUI draws real calculated star positions over either the existing night palette or a portrait AVFoundation preview. AppModel owns session alignment and sky navigation.

**Tech stack:** Swift 5 / SwiftUI / Core Motion / AVFoundation; iOS 17 minimum. No new runtime package, network service, or generated artwork is needed.

## Global constraints

- Keep <=25° rough guidance, <=10° discovery, heading <=2s, motion <=0.25s, movement/location/horizon gates. Manual sky alignment must never improve measured accuracy or unlock discovery.
- New constellation lines use real catalog star IDs and original sparse connections. Additional coordinates come from the IAU-hosted star-name table; preserve source/attribution and the existing commercial-release gate.
- Camera permission is requested only after the camera action. Denial/unavailable/interruption retains a usable star chart. Preview only: no microphone, recording, photo-library access, persistence, or upload.
- Camera uses the rear wide lens, portrait orientation, measured format FOV and aspect-fill projection. No zoom/stabilization crop assumptions; camera and sensor behavior still need physical-device verification.
- One visible named star can correct a local angular offset <=25°. Explain that it is a user alignment, not automatic star detection. Clear it on retry, star change, route exit, background, and north-reference changes.
- Japanese/English, VoiceOver, large text and Reduce Motion remain supported. Keep the existing low-luminance visual language and return navigation.

## Review focus

1. North wrap, zenith/roll, behind-camera targets and invalid geometry must not mirror or teleport stars.
2. Cropped portrait camera and overlays must share the same optical center and focal scale.
3. Permission completion after exit, interruptions and background must not restart capture.
4. Manual alignment must not masquerade as sensor calibration or bypass any existing safety gate.
5. Navigation to another star, including newly displayed stars, must retain the right identity and clear old alignment.

## Tasks

- [x] **1 — Projection and alignment.** Add `SkyProjection.swift` and `SkyProjectionTests.swift`. Test center/right/up, 0/360 wrap, roll/zenith, portrait crop, behind/horizon/invalid input, bounded alignment and neighbor geometry. Run targeted CI against the stub first, then the real implementation.
- [x] **2 — Catalog and sensor snapshot.** Add `SkyCatalog.swift` with source-tagged real stars and original ID edges; validate uniqueness/endpoints. Capture camera-up in `SensorService` / `DirectionSensorSnapshot`; compute all sky observations in `AppModel`. Use the same snapshot as readiness.
- [x] **3 — Camera and experience.** Add a preview-only lifecycle service and UIViewRepresentable. Replace schematic constellation canvas with a shared real sky field; reveal it near the target in Finder, offer direct sky access, and retain the result/return flow. Add explicit camera toggle, named-star alignment and next-visible-star navigation.
- [x] **4 — Verify and deliver Build 7.** Add both-language copy/privacy text, camera usage description and portrait config; update IPA/UI verification. Review the branch, run targeted and full Swift tests plus iPhone build, inspect rendered production sky/copy, verify/download IPA if free storage is confirmed, and update the existing local HANDOFF only.

## Evidence and decisions

- Existing Build 6: 59 tests passed; user reports improved behavior. Complete real-device safety/accuracy verification remains open.
- No local Swift/Xcode runtime is available; standard public GitHub macOS CI supplies executable Swift tests and iPhone compilation. Keep artifact uploads off until current free storage is checked.
- Figma/Context7/Firecrawl/Runway/GitHub connector actions are not exposed in this session. Use available tools and existing visual components; do not claim connector execution.
- RED: [38093263050](https://github.com/khunryo/hear-stars/actions/runs/38093263050), source f67c346: projection stubs compiled; 8 expected unwrap failures, 3 fail-closed sky tests passed.
- GREEN final: [38094374070](https://github.com/khunryo/hear-stars/actions/runs/38094374070), source 11ea0b00e152dfb921f9d9b249fdc9eee87cde7c: targeted 42 / full 75 tests, zero failures, iPhone Release compile, JA/EN 250 bundled translations each, portrait-only and camera permission plist checks passed.
- Downloaded artifact 11685581406; ZIP digest matched GitHub metadata. IPA 0.1.0(7), 1,460,335 bytes, SHA256 `98aba1636f98f2d1f66da7bce64c42b6d5a1789fcac3ba41c3d5fb22f3aa9019`. Local IPA verification repeated successfully; Japanese/English production sky-field/copy renders visually inspected (not full iPhone screenshots).
- Chrome billing on 2026-10-11: Actions billable $0, storage 0/0.5GB before upload. Artifact ~1.97MB, one-day retention, no cache; upload guard restored OFF after download. No billing changes.

### Standards review

Fixed point Build 6 abb02feb through implementation 5e17c06. Two P2 findings: Canvas star-name fonts did not scale; Reduce Motion did not stop chart motion. Commit 11ea0b0 added scaled fonts/collision spacing and an explicitly labeled still chart with manual refresh, disabling/stopping camera in that mode. Independent follow-up found no further actionable standards findings. No Fowler heuristic findings.

### Spec review

One P2 finding: fixed-size star labels violated large-text support (overlaps the standards finding, counted separately). Addressed in 11ea0b0; independent follow-up found no concrete regressions. No definite projection, lifecycle, navigation or safety-gate bypass found by static review.

### Remaining real-device gate

Camera registration/FOV/roll, permission/interruption/background races, Dynamic Type/VoiceOver/Reduce Motion on iPhone and outdoor discovery must be exercised using `08-field-test.md`. Existing intermittent sensor stops are not claimed fully fixed. Added-star proper-motion approximations and Gamma Cas epoch assumption are documented in `11-sky-data.md`; signature and commercial rights gates remain open. Stop at this downloadable-test-build milestone.
