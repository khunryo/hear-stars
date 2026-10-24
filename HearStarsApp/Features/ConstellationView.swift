import HearStarsCore
import SwiftUI

struct ConstellationView: View {
    @ObservedObject var model: AppModel
    @StateObject private var camera = CameraPreviewService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraWanted = false
    @State private var visible = false
    @State private var aligning = false
    @State private var alignmentFailed = false
    @State private var stillRevision = 0
    @State private var showingConstellations = false
    @State private var showingCredits = false
    private static let dataNotices = SkyCatalog.noticesURL.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                HStack {
                    Button(action: model.leaveSky) {
                        Label(LocalizedStringKey(model.skyReturnRoute == .finder ? "sky.backToFinding" :
                            (model.skyReturnRoute == .picker ? "common.backToStars" : "constellation.backToResult")),
                              systemImage: "chevron.left")
                            .font(.subheadline).frame(minHeight: 44)
                    }
                    Spacer()
                    Text("sky.title").font(.headline)
                }
                if model.diagnosticsExpanded || dynamicTypeSize.isAccessibilitySize || geometry.size.height < 740 {
                    ScrollView { content(fieldHeight: 280) }
                } else {
                    content(fieldHeight: nil)
                }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 14)
        }
        .onAppear { visible = true }
        .onDisappear { visible = false; cameraWanted = false; aligning = false; camera.stop() }
        .onChange(of: cameraWanted) { _, wanted in
            aligning = false
            if wanted { startCameraIfVisible() } else { camera.stop() }
        }
        .onChange(of: scenePhase) { _, phase in
            aligning = false
            if phase == .active { if cameraWanted { startCameraIfVisible() } }
            else { camera.stop() }
        }
        .onChange(of: camera.state) { _, state in if state != .running { aligning = false } }
        .onChange(of: reduceMotion) { _, enabled in if enabled { cameraWanted = false; camera.stop() } }
        .onChange(of: model.directionReadiness) { _, readiness in
            if !readiness.canUseDirection { aligning = false }
        }
        .sheet(isPresented: $showingConstellations) { SkyTargetListView(model: model) }
        .sheet(isPresented: $showingCredits) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sky.fullCredits")
                        Text(verbatim: Self.dataNotices).textSelection(.enabled)
                    }.font(.footnote).padding()
                }
                    .navigationTitle(Text("sky.sources"))
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("sky.done") { showingCredits = false } } }
            }.preferredColorScheme(.dark)
        }
        .onChange(of: showingConstellations) { _, shown in handleSheet(shown) }
        .onChange(of: showingCredits) { _, shown in handleSheet(shown) }
    }

    private func content(fieldHeight: CGFloat?) -> some View {
        VStack(spacing: 10) {
            DirectionStatusView(model: model)
            ZStack {
                Color.hsNight
                if camera.state == .running && !reduceMotion { CameraPreview(session: camera.session) }
                if !aligning {
                    SkyField(observations: model.observations, pose: chartPose,
                             selectedStarID: model.skyDisplayedStarID,
                             cameraFieldOfView: camera.metrics?.landscapeFieldOfView,
                             cameraAspectRatio: camera.metrics?.landscapeAspectRatio,
                             selectedConstellationID: model.selectedSkyConstellationID,
                             onSelect: model.selectSkyTarget)
                        .id(stillRevision)
                } else { SkyReticle() }
                if model.skyPose == nil {
                    Text("sky.sensorPaused").font(.subheadline).multilineTextAlignment(.center)
                        .padding(20).background(Color.hsNight.opacity(0.85))
                }
            }
            .frame(height: fieldHeight).frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.format("sky.accessibility", model.skySelectionTitle)))
            VStack(spacing: 4) {
                Text(verbatim: model.skySelectionTitle).font(.title3.weight(.medium))
                if model.selectedSkyConstellationID != nil, let anchor = model.skyGuideStar {
                    Text(L10n.format("sky.anchor", L10n.string(anchor.nameKey)))
                        .font(.subheadline).foregroundStyle(Color.hsSecondary)
                } else if let group = SkyCatalog.constellation(for: model.selectedStarID) {
                    Text(LocalizedStringKey(group.nameKey)).font(.subheadline).foregroundStyle(Color.hsSecondary)
                }
                Text(LocalizedStringKey(reduceMotion ? "sky.stillHint" : "sky.hint"))
                    .font(.caption).foregroundStyle(Color.hsSecondary).multilineTextAlignment(.center)
            }.accessibilityElement(children: .combine)
            if !SkyCatalog.catalogIsExpanded { Text("sky.catalogUnavailable").font(.caption) }
            if aligning {
                Text(L10n.format("sky.alignInstruction", L10n.string(model.skyGuideStar?.nameKey ?? model.selectedStar.nameKey)))
                    .font(.subheadline).multilineTextAlignment(.center)
                if alignmentFailed { Text("sky.alignTooFar").font(.caption).foregroundStyle(Color.hsGuide) }
                HStack {
                    Button("sky.alignCancel") { aligning = false }.frame(minHeight: 44)
                    Spacer()
                    Button("sky.alignConfirm") {
                        if model.alignSkyToSelectedStar() { aligning = false }
                        else { alignmentFailed = true }
                    }.frame(minHeight: 44).disabled(!model.directionReadiness.canUseDirection)
                }.frame(minHeight: 44)
            } else {
                HStack {
                    if reduceMotion {
                        Button("sky.refreshStill") { stillRevision += 1 }.frame(minHeight: 44)
                    } else {
                        Button { cameraWanted.toggle() } label: {
                            Label(LocalizedStringKey(cameraWanted ? "sky.cameraOff" : "sky.cameraOn"), systemImage: "camera")
                        }.frame(minHeight: 44)
                    }
                    Spacer()
                    if camera.state == .running && !model.isPractice {
                        Button("sky.align") {
                            model.clearSkyAlignment(); alignmentFailed = false; aligning = true
                        }.frame(minHeight: 44).disabled(!model.directionReadiness.canUseDirection || model.skyGuideStar == nil)
                    }
                }.font(.subheadline)
                if model.skyAlignment != nil {
                    HStack {
                        Text("sky.aligned").font(.caption)
                        Spacer()
                        Button("sky.alignReset", action: model.clearSkyAlignment).frame(minHeight: 44)
                    }.font(.caption).foregroundStyle(Color.hsSecondary)
                }
            }
            cameraMessage
            Button(action: model.guideToSkyTarget) {
                Text("sky.guideSelected")
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.hsDiscovery))
                    .foregroundStyle(Color.hsNight)
            }
            .disabled(model.skyGuideStar == nil || !model.directionReadiness.canUseDirection)
            .opacity(model.skyGuideStar == nil || !model.directionReadiness.canUseDirection ? 0.45 : 1)
            if model.skyGuideStar == nil { Text("sky.notVisible").font(.caption).foregroundStyle(Color.hsSecondary) }
            Button("sky.constellationList") { showingConstellations = true }.frame(minHeight: 44)
            if model.skyReturnRoute == .discovery, let next = model.nextSkyStar {
                Button(L10n.format("sky.nextStar", L10n.string(next.nameKey)), action: model.findNextSkyStar).frame(minHeight: 44)
            }
            Button("sky.sources") { showingCredits = true }.font(.caption).frame(minHeight: 44)
        }.buttonStyle(.plain).tint(Color.hsDiscovery)
    }

    @ViewBuilder private var cameraMessage: some View {
        switch camera.state {
        case .requesting: Text("sky.cameraPreparing").font(.caption)
        case .denied:
            Text("sky.cameraDenied").font(.caption)
            Button("readiness.openSettings", action: model.openAppSettings).frame(minHeight: 44)
        case .unavailable, .interrupted:
            Text("sky.cameraUnavailable").font(.caption)
            Button("readiness.retry") { startCameraIfVisible() }.frame(minHeight: 44)
        case .running: Text("sky.cameraHint").font(.caption).foregroundStyle(Color.hsSecondary)
        case .off: EmptyView()
        }
    }

    private func startCameraIfVisible() {
        guard visible, cameraWanted, !reduceMotion, !showingConstellations, !showingCredits, scenePhase == .active else { return }
        Task {
            // Recheck inside the queued task: leaving the view may have won the race.
            guard visible, cameraWanted, !reduceMotion, !showingConstellations, !showingCredits, scenePhase == .active else { return }
            await camera.start()
        }
    }
    private func handleSheet(_ shown: Bool) {
        aligning = false
        if shown { camera.stop() } else if cameraWanted { startCameraIfVisible() }
    }
    private var chartPose: SkyPose? {
        guard let live = model.skyPose else { return nil }
        guard reduceMotion, let target = model.selectedObservation else { return live }
        return SkyPose(aim: .init(azimuthDegrees: target.azimuthDegrees, altitudeDegrees: target.altitudeDegrees))
    }
}
