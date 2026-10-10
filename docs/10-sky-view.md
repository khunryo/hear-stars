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

- [ ] **1 — Projection and alignment.** Add `SkyProjection.swift` and `SkyProjectionTests.swift`. Test center/right/up, 0/360 wrap, roll/zenith, portrait crop, behind/horizon/invalid input, bounded alignment and neighbor geometry. Run targeted CI against the stub first, then the real implementation.
- [ ] **2 — Catalog and sensor snapshot.** Add `SkyCatalog.swift` with source-tagged real stars and original ID edges; validate uniqueness/endpoints. Capture camera-up in `SensorService` / `DirectionSensorSnapshot`; compute all sky observations in `AppModel`. Use the same snapshot as readiness.
- [ ] **3 — Camera and experience.** Add a preview-only lifecycle service and UIViewRepresentable. Replace schematic constellation canvas with a shared real sky field; reveal it near the target in Finder, offer direct sky access, and retain the result/return flow. Add explicit camera toggle, named-star alignment and next-visible-star navigation.
- [ ] **4 — Verify and deliver Build 7.** Add both-language copy/privacy text, camera usage description and portrait config; update IPA/UI verification. Review the branch, run targeted and full Swift tests plus iPhone build, inspect rendered production sky/copy, verify/download IPA if free storage is confirmed, and update the existing local HANDOFF only.

## Evidence and decisions

- Existing Build 6: 59 tests passed; user reports improved behavior. Complete real-device safety/accuracy verification remains open.
- No local Swift/Xcode runtime is available; standard public GitHub macOS CI supplies executable Swift tests and iPhone compilation. Keep artifact uploads off until current free storage is checked.
- Figma/Context7/Firecrawl/Runway/GitHub connector actions are not exposed in this session. Use available tools and existing visual components; do not claim connector execution.
