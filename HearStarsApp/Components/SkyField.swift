import HearStarsCore
import SwiftUI

/// Production star field, also rendered by the macOS verification tool.
struct SkyField: View {
    let observations: [String: HorizontalCoordinate]
    let pose: SkyPose?
    let selectedStarID: String
    var showNeighbors = true
    var cameraFieldOfView: Double? = nil
    var cameraAspectRatio: Double? = nil
    var bundle: Bundle = .main
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var selectedLabelSize = 14.0
    @ScaledMetric(relativeTo: .caption) private var neighborLabelSize = 11.0
    @State private var stillPose: SkyPose?
    @State private var stillObservations: [String: HorizontalCoordinate] = [:]

    var body: some View {
        Canvas { context, size in
            guard let livePose = pose,
                  let pose = reduceMotion ? stillPose : livePose else { return }
            let fieldObservations = reduceMotion ? stillObservations : observations
            let viewport: SkyViewport
            if let fov = cameraFieldOfView, let aspect = cameraAspectRatio {
                viewport = .camera(width: size.width, height: size.height,
                    landscapeFieldOfViewDegrees: fov, landscapeAspectRatio: aspect)
            } else {
                viewport = .init(width: size.width, height: size.height)
            }
            var points: [String: CGPoint] = [:]
            for star in SkyCatalog.stars where showNeighbors || star.id == selectedStarID {
                guard let target = fieldObservations[star.id],
                      let point = SkyProjection.project(target, pose: pose, viewport: viewport),
                      (-2...3).contains(point.x), (-2...3).contains(point.y) else { continue }
                points[star.id] = CGPoint(x: point.x * size.width, y: point.y * size.height)
            }
            if showNeighbors {
                for constellation in SkyCatalog.constellations {
                    let isSelected = constellation.starIDs.contains(selectedStarID)
                    for (a, b) in constellation.links {
                        guard let from = points[a], let to = points[b] else { continue }
                        var path = Path(); path.move(to: from); path.addLine(to: to)
                        context.stroke(path, with: .color(isSelected ? .hsDiscovery.opacity(0.8) : .hsSecondary.opacity(0.5)),
                                       lineWidth: isSelected ? 1.1 : 0.8)
                    }
                }
            }
            var labelCenters: [CGPoint] = []
            let ordered = SkyCatalog.stars.sorted {
                if ($0.id == selectedStarID) != ($1.id == selectedStarID) { return $0.id == selectedStarID }
                return $0.visualMagnitude < $1.visualMagnitude
            }
            for star in ordered {
                guard let p = points[star.id], p.x >= 0, p.x <= size.width, p.y >= 0, p.y <= size.height else { continue }
                let selected = star.id == selectedStarID
                let radius = selected ? 4.0 : max(1.7, 3.4 - star.visualMagnitude * 0.35)
                let disc = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: disc), with: .color(selected ? .hsDiscovery : .hsText))
                if selected {
                    context.stroke(Path(ellipseIn: CGRect(x: p.x - 12, y: p.y - 12, width: 24, height: 24)),
                                   with: .color(.hsDiscovery.opacity(0.8)), lineWidth: 0.8)
                }
                let scale = selectedLabelSize / 14
                let margin = min(size.width / 2, 65 * scale)
                let label = CGPoint(x: min(max(p.x, margin), size.width - margin), y: p.y + 24 * scale)
                guard label.y < size.height - 12,
                      selected || (star.visualMagnitude <= 3.6 && !labelCenters.contains(where: {
                          abs($0.x - label.x) < 95 * scale && abs($0.y - label.y) < 25 * scale
                      })) else { continue }
                context.draw(Text(verbatim: L10n.string(star.nameKey, bundle: bundle))
                    .font(.system(size: selected ? selectedLabelSize : neighborLabelSize, weight: selected ? .medium : .regular))
                    .foregroundStyle(selected ? Color.hsText : .hsSecondary), at: label)
                labelCenters.append(label)
            }
        }
        .clipped()
        .accessibilityHidden(true)
        .onAppear { captureStillField() }
        .onChange(of: pose) { _, _ in if stillPose == nil { captureStillField() } }
        .onChange(of: selectedStarID) { _, _ in captureStillField() }
        .onChange(of: reduceMotion) { _, _ in captureStillField() }
    }
    private func captureStillField() { stillPose = pose; stillObservations = observations }
}

struct SkyReticle: View {
    var body: some View {
        ZStack {
            Circle().stroke(Color.hsText.opacity(0.8), lineWidth: 0.8).frame(width: 36, height: 36)
            Rectangle().fill(Color.hsText).frame(width: 1, height: 8).offset(y: -25)
            Rectangle().fill(Color.hsText).frame(width: 1, height: 8).offset(y: 25)
            Rectangle().fill(Color.hsText).frame(width: 8, height: 1).offset(x: -25)
            Rectangle().fill(Color.hsText).frame(width: 8, height: 1).offset(x: 25)
        }
        .accessibilityHidden(true)
    }
}
