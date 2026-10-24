# Full Sky Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task in the current session. Steps use checkbox syntax for tracking.

**Goal:** Display all 88 constellations with many real stars, select either from the chart, and guide with the existing sound/haptic engines.

**Architecture:** Bundle an auditable, compact catalog in HearStarsCore. One shared projection/layout drives drawing and tap candidates. AppModel resolves constellation choices to an above-horizon anchor star and starts the unchanged Finder only on explicit action.

**Tech Stack:** Swift 5/SwiftUI/iOS17, Foundation Codable JSON resources, Python3 offline data conversion. No added runtime dependency or network service.

**Spec:** docs/12-full-sky.md (approved chat, details delegated).

## Global Constraints

- 88 constellations; merge Serpens subdivisions; keep original31 IDs/proper motions; reject unmatched line endpoints.
- Rough guidance<=25°, discovery<=10°, heading<=2s, motion<=0.25s; preserve all other safety gates. Vertical-warning bug remains unresolved.
- Explicit guide action, no guide pulses during browsing; camera optional/preview-only; no telemetry or image recognition.
- JA/EN, VoiceOver selection alternative, Dynamic Type and reduced-motion still field.
- Source pinning/checksums and bundled MIT/BSD notices; do not claim commercial clearance or actual-device verification.

## Review Focus

- Selecting a constellation must target its brightest visible member, not a below-horizon star or previous selection.
- A star tap/constellation-label tap must use the same projected positions and crop as drawing, with44pt-friendly hit areas.
- Original31 identities and constellation memberships must not duplicate/lose stars after coordinate matching.
- Browsing in southern latitudes must work even if previous selectedPolaris is below horizon; start-guide remains horizon-gated.
- Repeated observation updates must not recalculate thousands of precessions on every0.1s tick; blocked sensors must not imply alignment.

## Task1 — Auditable catalog and selection core

Files: tools/import_full_sky.py, its Python unit tests; Sources/HearStarsCore/{Resources,FullSkyCatalog,SkyCatalog,SkySelection,SkyProjection}.swift; core tests; Package.swift/project.yml.
Interfaces: SkyCatalog.stars/constellations preserve current signatures. SkySelection.star(String)/constellation(String). SkyCatalog.anchor(for: String, observations: [String:HorizontalCoordinate])->Star?. SkyPicking.nearest(to: SkyPoint, candidates:[SkyPickCandidate], viewport:SkyViewport, radiusPoints:Double)->SkySelection?. SkyPoint.init(x:y:) is public.

- [ ] Write ExpandedSkyTests:88unique groups, >=5000 real stars, valid endpoints, originalIDs preserved. Run on existing implementation; observe counts fail rather than compile failure.
- [ ] Write importer tests: J2000sexagesimal signs/hours; near0/360 match; reject a distant endpoint; mergeSerpens. Run and observe expected missing converter failure.
- [ ] Pin candidate sources, import with bounded match distance, produce compact JSON and notices; verify88 groups/no missing endpoints; document any match uncertainty.
- [ ] Add resource loading for SPM/Xcode/macOS-renderer; no silent empty-catalog success. Run catalog tests GREEN.
- [ ] Write/run RED then implement anchor and nearest-pick behavior: visible>=5deg, brightest, missing/unknownnil; exact/nearest/outside/priority with literal positions.
- [ ] Verify relevant tests and commit Task1 to existing codex branch (not main).

## Task2 — Browse, tap and guide

Files: HearStarsApp/{Components/SkyField,Features/{ConstellationView,TargetPickerView,SkyTargetListView},App/AppModel}, JA/ENstrings; core interaction tests as needed.
Consumes: catalog/selection/anchor/picking from Task1. Produces: model.browseSky(), selectSkyTarget(_:SkySelection), guideToSkyTarget(); UI uses the same projected candidate positions for draw and taps.

- [ ] Add tests for selection resolution/eligibility before implementation; confirm RED then implement shared resolver.
- [ ] Add main browse action and picker return; allow full-sky pose independently of selected-star altitude, keep physical sensors/readiness gates.
- [ ] Draw many star dots, actual constellation lines and sparse labels; support selected target, scaled labels, reduced-motion frozen pose, shared label hit candidates.
- [ ] Select with a tap or accessible constellation list. Show selectedconstellation+anchor name; explicit guide action uses correct star, existing modes and guidemapper; clear alignment on target change/leave.
- [ ] Throttle expensive world-coordinate updates to1s with location/date/practice invalidation; reuse cached sort/index.
- [ ] Run focused tests/audit; inspect diff against safety constraints; commit Task2.

## Task3 — Verify and hand off

Files: project.yml Build8, tools/{audit_project,verify_ipa,verify_readiness_ui}, .github/workflows/ios-unsigned.yml, docs/14-full-sky-data.md, HANDOFF_CURRENT.md (local only).

- [ ] Add bundled data/notice/88group assertions and both-language production chart renders.
- [ ] Run targeted tests, full suite once at milestone, iPhone Release compilation. Record exact results; localWindows has no Swift/Xcode so use authorized existing standard public GitHubMac workflow.
- [ ] Fresh whole-change review, fix important findings with regression tests. No merge/main or commercial release.
- [ ] Verify free storage before artifact upload; if available download/verify Build8 without overwritingBuild7; turn upload OFF again. If unavailable preserve tested sources and report exact limit.
- [ ] Update existing localHANDOFF with completed/pending/unverified results and next single action; stop at test-build milestone.

## Execution notes

- Existing native checkout on codex/readiness-return-flow is the selected app; do not spawn a second user chat or touch other apps. Work inline. Only final review may delegate as required by the execution skill.
- Canonical path resolves through the oldjunction to C:/dev/Codex-Projects/01-apps/_shared/fishing/hear-stars. The declared cwd worktree is gone. Read/write/git commands need appropriate scoped approval; do not rebuild or overwrite stale copies.
