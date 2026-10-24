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

    public mutating func select(_ selection: SkySelection) {
        self.selection = selection
    }

    public mutating func beginGuidance(starID: String, selection: SkySelection? = nil) {
        if let selection { self.selection = selection }
        guidanceSelection = self.selection
        guidanceStarID = starID
    }

    public mutating func cancelSelection() { selection = guidanceSelection }
}

public enum SkyChartPose {
    public static func resolve(reduceMotion: Bool, selection: SkySelection,
                               observations: [String: HorizontalCoordinate], livePose: SkyPose?) -> SkyPose? {
        guard reduceMotion else { return livePose }
        // A static chart uses computed sky positions, not the phone's compass.
        let preferred = SkySelectionResolver.star(for: selection, observations: observations)
        let visible = preferred ?? SkyCatalog.starsByBrightness.first {
            (observations[$0.id]?.altitudeDegrees ?? -.infinity) >= 5
        }
        guard let star = visible, let target = observations[star.id] else { return nil }
        return SkyPose(aim: .init(azimuthDegrees: target.azimuthDegrees, altitudeDegrees: target.altitudeDegrees))
    }
}
