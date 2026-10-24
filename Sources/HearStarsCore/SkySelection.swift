import Foundation

public enum SkySelection: Equatable, Sendable {
    case star(String)
    case constellation(String)
}
public struct SkyPickCandidate: Equatable, Sendable {
    public let selection: SkySelection
    public let position: SkyPoint
    public let priority: Int
    public let hitWidthPoints: Double?
    public let hitHeightPoints: Double?
    public init(_ selection: SkySelection, at position: SkyPoint, priority: Int = 0,
                hitWidthPoints: Double? = nil, hitHeightPoints: Double? = nil) {
        self.selection = selection; self.position = position; self.priority = priority
        self.hitWidthPoints = hitWidthPoints; self.hitHeightPoints = hitHeightPoints
    }
}
public enum SkyPicking {
    public static func nearest(to point: SkyPoint, candidates: [SkyPickCandidate],
        viewport: SkyViewport, radiusPoints: Double = 28) -> SkySelection? {
        guard point.x.isFinite, point.y.isFinite, viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 0, viewport.height > 0, radiusPoints.isFinite, radiusPoints > 0 else { return nil }
        var closest: SkyPickCandidate?
        var closestDistance = Double.infinity
        for candidate in candidates {
            guard candidate.position.x.isFinite, candidate.position.y.isFinite else { continue }
            let dx = (candidate.position.x - point.x) * viewport.width
            let dy = (candidate.position.y - point.y) * viewport.height
            let distance = hypot(dx, dy)
            let contains: Bool
            if let width = candidate.hitWidthPoints, let height = candidate.hitHeightPoints {
                guard width.isFinite, height.isFinite, width > 0, height > 0 else { continue }
                contains = abs(dx) <= width / 2 && abs(dy) <= height / 2
            } else { contains = distance <= radiusPoints }
            guard contains else { continue }
            if closest == nil || candidate.priority > closest!.priority
                || (candidate.priority == closest!.priority && distance < closestDistance) {
                closest = candidate; closestDistance = distance
            }
        }
        return closest?.selection
    }
}
public enum SkySelectionResolver {
    public static func star(for selection: SkySelection, observations: [String: HorizontalCoordinate]) -> Star? {
        switch selection {
        case .star(let id):
            guard let star = SkyCatalog.starsByID[id], let observation = observations[id],
                  observation.altitudeDegrees >= 2 else { return nil }
            return star
        case .constellation(let id):
            return SkyCatalog.anchor(for: id, observations: observations)
        }
    }
}
public struct SkyObservationSchedule {
    private var lastDate: Date?
    private var lastObserver: ObserverLocation?
    private var lastPractice: Bool?
    public init() {}
    public mutating func shouldRecalculate(at date: Date, observer: ObserverLocation, isPractice: Bool) -> Bool {
        let elapsed = lastDate.map { date.timeIntervalSince($0) }
        guard lastObserver != observer || lastPractice != isPractice
                || elapsed == nil || elapsed! >= 1 || elapsed! < 0 else { return false }
        lastDate = date; lastObserver = observer; lastPractice = isPractice
        return true
    }
}
