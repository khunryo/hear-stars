import HearStarsCore
import SwiftUI

/// Drawing and picking share one layout, including the camera crop and frozen pose.
struct SkyField: View {
    let observations: [String: HorizontalCoordinate]
    let pose: SkyPose?
    let selectedStarID: String
    var showNeighbors = true
    var cameraFieldOfView: Double? = nil
    var cameraAspectRatio: Double? = nil
    var bundle: Bundle = .main
    var selectedConstellationID: String? = nil
    var onSelect: ((SkySelection) -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var selectedLabelSize = 14.0
    @ScaledMetric(relativeTo: .caption) private var neighborLabelSize = 11.0
    @State private var stillPose: SkyPose?
    @State private var stillObservations: [String: HorizontalCoordinate] = [:]

    var body: some View {
        GeometryReader { geometry in
            let field = layout(in: geometry.size)
            Canvas { context, size in
                if showNeighbors {
                    for group in SkyCatalog.constellations {
                        let selected = group.id == (selectedConstellationID ?? SkyCatalog.constellation(for: selectedStarID)?.id)
                        for (a, b) in group.links {
                            guard let from = field.points[a], let to = field.points[b] else { continue }
                            var line = Path(); line.move(to: from); line.addLine(to: to)
                            context.stroke(line, with: .color(selected ? .hsDiscovery.opacity(0.8) : .hsSecondary.opacity(0.48)),
                                           lineWidth: selected ? 1.1 : 0.7)
                        }
                    }
                }
                for star in SkyCatalog.starsByBrightness {
                    guard let p = field.points[star.id], isInside(p, size) else { continue }
                    let selected = star.id == selectedStarID
                    let radius = selected ? 4.0 : max(0.75, 3.5 - star.visualMagnitude * 0.42)
                    context.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
                                 with: .color(selected ? .hsDiscovery : .hsText.opacity(star.visualMagnitude > 5 ? 0.55 : 0.9)))
                    if selected {
                        context.stroke(Path(ellipseIn: CGRect(x: p.x - 12, y: p.y - 12, width: 24, height: 24)),
                                       with: .color(.hsDiscovery), lineWidth: 0.8)
                    }
                }
                for label in field.labels {
                    context.draw(Text(verbatim: L10n.string(label.key, bundle: bundle))
                        .font(.system(size: label.selected ? selectedLabelSize : neighborLabelSize,
                                      weight: label.isConstellation ? .medium : .regular))
                        .foregroundStyle(label.selected ? Color.hsDiscovery : .hsText), at: label.point)
                }
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { tap in
                guard onSelect != nil else { return }
                if let target = SkyPicking.nearest(
                    to: .init(x: tap.location.x / max(1, geometry.size.width), y: tap.location.y / max(1, geometry.size.height)),
                    candidates: field.candidates, viewport: viewport(geometry.size)) { onSelect?(target) }
            })
        }
        .clipped().accessibilityHidden(true)
        .onAppear { captureStillField() }
        .onChange(of: pose) { _, _ in if stillPose == nil { captureStillField() } }
        .onChange(of: selectedStarID) { _, _ in captureStillField() }
        .onChange(of: reduceMotion) { _, _ in captureStillField() }
    }

    private func viewport(_ size: CGSize) -> SkyViewport {
        if let fov = cameraFieldOfView, let aspect = cameraAspectRatio {
            return .camera(width: size.width, height: size.height,
                           landscapeFieldOfViewDegrees: fov, landscapeAspectRatio: aspect)
        }
        return .init(width: size.width, height: size.height)
    }
    private func layout(in size: CGSize) -> FieldLayout {
        var field = FieldLayout()
        guard pose != nil, let actualPose = reduceMotion ? stillPose : pose,
              size.width > 0, size.height > 0 else { return field }
        let actualObservations = reduceMotion ? stillObservations : observations
        let viewport = viewport(size)
        for star in SkyCatalog.starsByBrightness where showNeighbors || star.id == selectedStarID {
            guard let target = actualObservations[star.id],
                  let p = SkyProjection.project(target, pose: actualPose, viewport: viewport),
                  (-2...3).contains(p.x), (-2...3).contains(p.y) else { continue }
            let point = CGPoint(x: p.x * size.width, y: p.y * size.height)
            field.points[star.id] = point
            if isInside(point, size) { field.candidates.append(.init(.star(star.id), at: p)) }
        }
        let scale = selectedLabelSize / 14
        func addLabel(_ key: String, at p: CGPoint, selected: Bool, target: SkySelection, constellation: Bool) {
            guard p.y > 12 * scale, p.y < size.height - 12 * scale else { return }
            let margin = min(size.width / 2, 70 * scale)
            let point = CGPoint(x: min(max(p.x, margin), size.width - margin), y: p.y)
            guard selected || !field.labels.contains(where: { abs($0.point.x - point.x) < 125 * scale && abs($0.point.y - point.y) < 28 * scale }) else { return }
            field.labels.append(.init(key: key, point: point, selected: selected, isConstellation: constellation))
            let fontSize = selected ? selectedLabelSize : neighborLabelSize
            let hitWidth = max(44, Double(L10n.string(key, bundle: bundle).count) * fontSize * 1.05)
            field.candidates.append(.init(target, at: .init(x: point.x / size.width, y: point.y / size.height),
                priority: constellation ? 2 : 1, hitWidthPoints: hitWidth, hitHeightPoints: max(44, fontSize * 1.5)))
        }
        if let point = field.points[selectedStarID], isInside(point, size), let star = SkyCatalog.starsByID[selectedStarID] {
            addLabel(star.nameKey, at: .init(x: point.x, y: point.y + 24 * scale), selected: true,
                     target: .star(star.id), constellation: false)
        }
        if showNeighbors {
            let selectedGroup = selectedConstellationID ?? SkyCatalog.constellation(for: selectedStarID)?.id
            let groups = SkyCatalog.constellations.sorted { ($0.id == selectedGroup) && ($1.id != selectedGroup) }
            for group in groups {
                let visible = group.starIDs.compactMap { field.points[$0] }.filter { isInside($0, size) }
                guard visible.count >= 2 else { continue }
                let point = CGPoint(x: visible.map(\.x).reduce(0, +) / Double(visible.count),
                                    y: visible.map(\.y).reduce(0, +) / Double(visible.count) - 30 * scale)
                addLabel(group.nameKey, at: point, selected: group.id == selectedGroup,
                         target: .constellation(group.id), constellation: true)
            }
            for star in SkyCatalog.starsByBrightness where star.id != selectedStarID && star.visualMagnitude <= 3.6 {
                guard star.nameKey.hasPrefix("star.") || star.nameKey.hasPrefix("skyStar."),
                      let point = field.points[star.id], isInside(point, size) else { continue }
                addLabel(star.nameKey, at: .init(x: point.x, y: point.y + 24 * scale), selected: false,
                         target: .star(star.id), constellation: false)
            }
        }
        return field
    }
    private func isInside(_ point: CGPoint, _ size: CGSize) -> Bool {
        point.x >= 0 && point.x <= size.width && point.y >= 0 && point.y <= size.height
    }
    private func captureStillField() { stillPose = pose; stillObservations = observations }
    private struct FieldLabel {
        let key: String
        let point: CGPoint
        let selected: Bool
        let isConstellation: Bool
    }
    private struct FieldLayout {
        var points: [String: CGPoint] = [:]
        var labels: [FieldLabel] = []
        var candidates: [SkyPickCandidate] = []
    }
}

struct SkyReticle: View {
    var body: some View {
        ZStack {
            Circle().stroke(Color.hsText.opacity(0.8), lineWidth: 0.8).frame(width: 36, height: 36)
            Rectangle().fill(Color.hsText).frame(width: 1, height: 8).offset(y: -25)
            Rectangle().fill(Color.hsText).frame(width: 1, height: 8).offset(y: 25)
            Rectangle().fill(Color.hsText).frame(width: 8, height: 1).offset(x: -25)
            Rectangle().fill(Color.hsText).frame(width: 8, height: 1).offset(x: 25)
        }.accessibilityHidden(true)
    }
}
