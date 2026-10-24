/// The chart's pending choice and the target currently producing guide pulses.
public struct SkyGuideSession {
    public private(set) var selection: SkySelection
    public private(set) var guidanceStarID: String
    private var guidanceSelection: SkySelection

    public init(starID: String = "polaris") {
        selection = .star(starID)
        guidanceSelection = selection
        guidanceStarID = starID
    }

    public mutating func select(_ selection: SkySelection, resolvedStarID: String?) {
        self.selection = selection
        if let resolvedStarID { guidanceStarID = resolvedStarID }
    }

    public mutating func beginGuidance(starID: String, selection: SkySelection? = nil) {
        if let selection { self.selection = selection }
        guidanceSelection = self.selection
        guidanceStarID = starID
    }

    public mutating func cancelSelection() {}
}

public enum SkyChartPose {
    public static func resolve(reduceMotion: Bool, selection: SkySelection,
                               observations: [String: HorizontalCoordinate], livePose: SkyPose?) -> SkyPose? {
        guard let livePose else { return nil }
        guard reduceMotion else { return livePose }
        let target: HorizontalCoordinate?
        switch selection {
        case .star(let id): target = observations[id]
        case .constellation:
            target = SkySelectionResolver.star(for: selection, observations: observations).flatMap { observations[$0.id] }
        }
        guard let target else { return livePose }
        return SkyPose(aim: .init(azimuthDegrees: target.azimuthDegrees, altitudeDegrees: target.altitudeDegrees))
    }
}
