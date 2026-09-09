import Foundation

/// Aligns an infrequent compass heading with the nearest predicted device heading.
///
/// Records are intentionally not interpolated: a gap in motion data must not make a
/// compass sample appear current. A `nil` heading represents a near-vertical sample
/// for which a top-edge heading is not meaningful.
public struct HeadingSamplePairing {
    public static let maximumPairingSkew: TimeInterval = 0.10

    private static let maximumRecordAge: TimeInterval = 2.0
    private static let maximumRecordCount = 64

    private struct Record {
        let headingDegrees: Double?
        let timestamp: TimeInterval
    }

    private var records: [Record] = []

    public init() {}

    /// Adds one Core Motion prediction. Out-of-order (including duplicate timestamp)
    /// observations are ignored so the retained stream is always monotonic.
    public mutating func record(
        headingDegrees: Double?,
        at timestamp: TimeInterval
    ) {
        guard timestamp.isFinite, timestamp >= 0,
              isValidHeading(headingDegrees),
              records.last.map({ timestamp > $0.timestamp }) ?? true else {
            return
        }

        records.append(
            Record(
                headingDegrees: headingDegrees.map(AngleMath.normalizeDegrees),
                timestamp: timestamp
            )
        )
        discardExpiredRecords(relativeTo: timestamp)
        if records.count > Self.maximumRecordCount {
            records.removeFirst(records.count - Self.maximumRecordCount)
        }
    }

    /// Returns the absolute wrapped angular disagreement, or `nil` when the compass
    /// sample cannot be paired with a valid, contemporaneous motion observation.
    public func residual(headingDegrees: Double, at timestamp: TimeInterval) -> Double? {
        guard timestamp.isFinite, timestamp >= 0,
              headingDegrees.isFinite, headingDegrees >= 0,
              let closestIndex = closestRecordIndex(to: timestamp) else {
            return nil
        }

        let closest = records[closestIndex]
        guard
              isWithinPairingWindow(timestamp, of: closest.timestamp),
              let predictedHeading = closest.headingDegrees else {
            return nil
        }

        return abs(AngleMath.signedDegrees(headingDegrees - predictedHeading))
    }

    public mutating func reset() {
        records.removeAll(keepingCapacity: false)
    }

    private func closestRecordIndex(to timestamp: TimeInterval) -> Int? {
        records.indices.min { lhs, rhs in
            abs(records[lhs].timestamp - timestamp) < abs(records[rhs].timestamp - timestamp)
        }
    }

    private func isWithinPairingWindow(_ timestamp: TimeInterval, of sampleTimestamp: TimeInterval) -> Bool {
        timestamp >= sampleTimestamp - Self.maximumPairingSkew
            && timestamp <= sampleTimestamp + Self.maximumPairingSkew
    }

    private mutating func discardExpiredRecords(relativeTo timestamp: TimeInterval) {
        let oldestAllowed = timestamp - Self.maximumRecordAge
        if let firstRetained = records.firstIndex(where: { $0.timestamp >= oldestAllowed }) {
            records.removeFirst(firstRetained)
        } else {
            records.removeAll(keepingCapacity: true)
        }
    }

    private func isValidHeading(_ headingDegrees: Double?) -> Bool {
        guard let headingDegrees else { return true }
        return headingDegrees.isFinite && headingDegrees >= 0
    }

}
