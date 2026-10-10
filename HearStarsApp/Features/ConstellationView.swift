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

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                HStack {
                    Button(action: model.leaveSky) {
                        Label(LocalizedStringKey(model.skyReturnRoute == .finder ? "sky.backToFinding" : "constellation.backToResult"),
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
    }

    private func content(fieldHeight: CGFloat?) -> some View {
        VStack(spacing: 10) {
            DirectionStatusView(model: model)
            ZStack {
                Color.hsNight
                if camera.state == .running && !reduceMotion { CameraPreview(session: camera.session) }
                if !aligning {
                    SkyField(observations: model.observations, pose: chartPose,
                             selectedStarID: model.selectedStarID,
                             cameraFieldOfView: camera.metrics?.landscapeFieldOfView,
                             cameraAspectRatio: camera.metrics?.landscapeAspectRatio)
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
            .accessibilityLabel(Text(L10n.format("sky.accessibility", L10n.string(model.selectedStar.nameKey))))
            VStack(spacing: 4) {
                Text(LocalizedStringKey(model.selectedStar.nameKey)).font(.title3.weight(.medium))
                if let group = SkyCatalog.constellation(for: model.selectedStarID) {
                    Text(LocalizedStringKey(group.nameKey)).font(.subheadline).foregroundStyle(Color.hsSecondary)
                }
                Text(LocalizedStringKey(reduceMotion ? "sky.stillHint" : "sky.hint"))
                    .font(.caption).foregroundStyle(Color.hsSecondary).multilineTextAlignment(.center)
            }.accessibilityElement(children: .combine)
            if aligning {
                Text(L10n.format("sky.alignInstruction", L10n.string(model.selectedStar.nameKey)))
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
                        }.frame(minHeight: 44).disabled(!model.directionReadiness.canUseDirection)
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
            if let next = model.nextSkyStar {
                Button(action: model.findNextSkyStar) {
                    Text(L10n.format("sky.nextStar", L10n.string(next.nameKey)))
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.hsDiscovery))
                        .foregroundStyle(Color.hsNight)
                }
            }
            Button("common.backToStars", action: model.returnToPicker).frame(minHeight: 44)
            DisclosureGroup("sky.sources") {
                Text("sky.credits").font(.caption).foregroundStyle(Color.hsSecondary)
                Link("IAU Catalog of Star Names", destination: URL(string: "https://iauarchive.eso.org/public/themes/naming_stars/")!)
                Link("Wikidata · Gamma Cassiopeiae", destination: URL(string: "https://www.wikidata.org/wiki/Q13584")!)
                Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
            }.font(.caption)
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
        guard visible, cameraWanted, !reduceMotion, scenePhase == .active else { return }
        Task {
            // Recheck inside the queued task: leaving the view may have won the race.
            guard visible, cameraWanted, !reduceMotion, scenePhase == .active else { return }
            await camera.start()
        }
    }
    private var chartPose: SkyPose? {
        guard let live = model.skyPose else { return nil }
        guard reduceMotion, let target = model.selectedObservation else { return live }
        return SkyPose(aim: .init(azimuthDegrees: target.azimuthDegrees, altitudeDegrees: target.altitudeDegrees))
    }
}
