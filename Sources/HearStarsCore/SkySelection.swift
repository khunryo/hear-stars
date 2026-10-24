import Foundation

public enum SkySelection: Equatable, Sendable {
    case star(String)
    case constellation(String)
}
public struct SkyPickCandidate: Equatable, Sendable {
    public let selection: SkySelection
    public let position: SkyPoint
    public let priority: Int
    public init(_ selection: SkySelection, at position: SkyPoint, priority: Int = 0) {
        self.selection = selection; self.position = position; self.priority = priority
    }
}
public enum SkyPicking {
    public static func nearest(to point: SkyPoint, candidates: [SkyPickCandidate],
        viewport: SkyViewport, radiusPoints: Double = 28) -> SkySelection? { nil }
}
public enum SkySelectionResolver {
    public static func star(for selection: SkySelection, observations: [String: HorizontalCoordinate]) -> Star? { nil }
}
public struct SkyObservationSchedule {
    public init() {}
    public mutating func shouldRecalculate(at date: Date, observer: ObserverLocation, isPractice: Bool) -> Bool { true }
}
