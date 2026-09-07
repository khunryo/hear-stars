import Foundation

public struct DiscoveryHoldTracker: Sendable {
    public let requiredDuration: TimeInterval
    private var enteredAt: Date?
    private var didTrigger = false

    public init(requiredDuration: TimeInterval = 0.8) {
        self.requiredDuration = requiredDuration
    }

    public mutating func update(isEligible: Bool, at date: Date) -> Bool {
        guard !didTrigger else { return false }
        guard isEligible else {
            enteredAt = nil
            return false
        }

        if enteredAt == nil {
            enteredAt = date
            return false
        }

        // Compare dates against the deadline. Subtracting their floating-point
        // timestamps can round an exact 0.8-second hold just below the threshold.
        if let enteredAt, date >= enteredAt.addingTimeInterval(requiredDuration) {
            didTrigger = true
            return true
        }
        return false
    }

    public mutating func reset() {
        enteredAt = nil
        didTrigger = false
    }
}
