import AppKit
import SwiftUI

/// Runs on the macOS builder using the app's actual copy view and the built
/// iPhone app's compiled localization tables. Fixed diagnostic fixtures exercise
/// the same assessment and readiness functions used by the app.
@main
struct VerifyReadinessUI {
    @MainActor
    static func main() throws {
        let appURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Diagnostic only: show how the previous expression becomes a format.
        let state = DirectionReadiness.calibrating
        let previousKey = LocalizedStringKey("readiness.\(state.rawValue).title")
        let previousRepresentation = Mirror(reflecting: previousKey).children
            .first(where: { $0.label == "key" })?.value
        print("Previous SwiftUI key representation: \(String(describing: previousRepresentation))")

        for language in ["ja", "en"] {
            guard let bundle = Bundle(url: appURL.appendingPathComponent("\(language).lproj")) else {
                fatalError("Missing built localization bundle: \(language)")
            }
            for state in DirectionReadiness.allCases {
                let copy = DirectionStatusCopy(state: state, bundle: bundle)
                precondition(!copy.title.isEmpty && !copy.title.hasPrefix("readiness."))
                precondition(!copy.detail.isEmpty && !copy.detail.hasPrefix("readiness."))
            }
            let calibrationCopy = DirectionStatusCopy(state: .calibrating, bundle: bundle)
            precondition(calibrationCopy.title == (
                language == "ja" ? "方角の調整が必要です" : "Direction needs adjusting"
            ))
            for issue in HeadingIssue.allCases {
                let prefix = "sensorIssue." + issue.rawValue
                let copy = DirectionStatusCopy(state: .calibrating, bundle: bundle, overridePrefix: prefix)
                precondition(!copy.title.isEmpty && copy.title != prefix + ".title")
                precondition(!copy.detail.isEmpty && copy.detail != prefix + ".body")
            }
            let motionCopy = DirectionStatusCopy(
                state: .checkingDirection, bundle: bundle, overridePrefix: "sensorIssue.motionWaiting"
            )
            precondition(!motionCopy.title.isEmpty && motionCopy.title != "sensorIssue.motionWaiting.title")
            precondition(!motionCopy.detail.isEmpty && motionCopy.detail != "sensorIssue.motionWaiting.body")
            for key in ["diagnostics.snapshot", "diagnostics.lastStop", "diagnostics.snapshotNote",
                        "diagnostics.yes", "diagnostics.no", "diagnostics.reference.trueNorth",
                        "diagnostics.reference.magnetic", "diagnostics.reference.arbitrary"] {
                let value = L10n.string(key, bundle: bundle)
                precondition(!value.isEmpty && value != key, "Missing diagnostics copy: \(key)")
            }
            for key in ["accuracy.approximate", "direction.vicinity", "finder.approximateFollowPulse",
                        "finder.approximateSoundHapticGuide", "finder.approximateVoiceStatus"] {
                let value = L10n.string(key, bundle: bundle)
                precondition(!value.isEmpty && value != key, "Missing approximate-guidance copy: \(key)")
            }

            let current = diagnostic(
                rawAccuracy: 14.5, residual: 0.9, gravityError: 0,
                motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
            )
            precondition(current.sensors.assessment.issue == nil)
            precondition(current.sensors.assessment.effectiveAccuracyDegrees == 14.5)
            precondition(current.state == .approximate, "Fresh ±14.5° should permit approximate guidance")
            precondition(current.copyPrefix == nil)

            let staleStop = diagnostic(
                rawAccuracy: 14.5, residual: 0.9, gravityError: 0,
                motionAge: 0.4, headingAge: 0.1, reference: .trueNorth,
                hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
            )
            precondition(staleStop.sensors.assessment.issue == nil)
            precondition(staleStop.state == .checkingDirection,
                         "Stale tilt must block guidance even with healthy compass values")
            precondition(staleStop.copyPrefix == "sensorIssue.motionWaiting")
            var history = DirectionDiagnosticHistory()
            history.record(staleStop)
            precondition(history.current == staleStop && history.lastStop == nil,
                         "An initially blocked reading is not a guidance stop")
            history.record(current)
            history.record(staleStop)
            precondition(history.current == staleStop && history.lastStop == staleStop,
                         "A guidance-to-blocked transition must freeze its stop reading")
            let stillBlocked = diagnostic(
                rawAccuracy: 14.5, residual: 0.9, gravityError: 3,
                motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
            )
            history.record(stillBlocked)
            precondition(history.current == stillBlocked && history.lastStop == staleStop,
                         "Blocked updates must not overwrite the frozen stop reading")
            history.record(current)
            precondition(history.lastStop == staleStop,
                         "A recovered guidance reading must retain the last stop")
            history.record(stillBlocked)
            precondition(history.lastStop == stillBlocked,
                         "The next guidance-to-blocked transition must replace the stop reading")
            history.clear()
            precondition(history.current == nil && history.lastStop == nil)

            let northUnavailable = diagnostic(
                rawAccuracy: 14.5, residual: 0.9, gravityError: 0,
                motionAge: 0.1, headingAge: 0.1, reference: .arbitrary,
                hasTrueHeading: false, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
            )
            precondition(northUnavailable.sensors.assessment.issue == .northUnavailable)
            precondition(northUnavailable.copyPrefix == "sensorIssue.northUnavailable")

            let gravityMismatch = diagnostic(
                rawAccuracy: 14.5, residual: 0.9, gravityError: 3,
                motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
            )
            precondition(gravityMismatch.sensors.assessment.issue == .gravityMismatch)
            precondition(gravityMismatch.copyPrefix == "sensorIssue.gravityMismatch")
            let issueFixtures: [(HeadingIssue, DirectionDiagnosticSnapshot)] = [
                (.headingWaiting, diagnostic(
                    rawAccuracy: 14.5, residual: 0.9, gravityError: 0,
                    motionAge: 0.1, headingAge: 2.1, reference: .trueNorth,
                    hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
                )),
                (.headingUnavailable, diagnostic(
                    rawAccuracy: -1, residual: 0.9, gravityError: 0,
                    motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                    hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
                )),
                (.northUnavailable, northUnavailable),
                (.magneticUncalibrated, diagnostic(
                    rawAccuracy: 14.5, residual: 0.9, gravityError: 0,
                    motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                    hasTrueHeading: true, magneticCalibrated: false, magneticKey: "diagnostics.magneticUncalibrated"
                )),
                (.gravityMismatch, gravityMismatch),
                (.sensorDisagreement, diagnostic(
                    rawAccuracy: 14.5, residual: 26, gravityError: 0,
                    motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                    hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
                )),
                (.headingUncertain, diagnostic(
                    rawAccuracy: 26, residual: 0.9, gravityError: 0,
                    motionAge: 0.1, headingAge: 0.1, reference: .trueNorth,
                    hasTrueHeading: true, magneticCalibrated: true, magneticKey: "diagnostics.magneticHigh"
                ))
            ]
            for (issue, diagnostic) in issueFixtures {
                let prefix = "sensorIssue." + issue.rawValue
                precondition(diagnostic.sensors.assessment.issue == issue)
                precondition(diagnostic.copyPrefix == prefix)
                let copy = DirectionStatusCopy(state: diagnostic.state, bundle: bundle, overridePrefix: diagnostic.copyPrefix)
                precondition(copy.title == L10n.string(prefix + ".title", bundle: bundle))
                precondition(copy.detail == L10n.string(prefix + ".body", bundle: bundle))
            }
            precondition(DirectionStatusCopy(
                state: staleStop.state, bundle: bundle, overridePrefix: staleStop.copyPrefix
            ).title == motionCopy.title)
            print("\(language): readiness, 7 sensor issue overrides, motion waiting, and diagnostics copy resolved")

            let observer = ObserverLocation(latitudeDegrees: 35.6812, longitudeDegrees: 139.7671)
            let date = ISO8601DateFormatter().date(from: "2026-01-15T12:00:00Z")!
            let observations = Dictionary(uniqueKeysWithValues: SkyCatalog.stars.map {
                ($0.id, AstronomyCalculator.horizontalCoordinate(for: $0, at: date, observer: observer))
            })
            for star in SkyCatalog.stars {
                precondition(L10n.string(star.nameKey, bundle: bundle) != star.nameKey)
            }
            for group in SkyCatalog.constellations {
                precondition(L10n.string(group.nameKey, bundle: bundle) != group.nameKey)
            }
            let content = VStack(alignment: .leading, spacing: 18) {
                Text(verbatim: L10n.string("sky.title", bundle: bundle)).font(.title2)
                ForEach(["polaris", "betelgeuse"], id: \.self) { id in
                    let target = observations[id]!
                    SkyField(observations: observations,
                        pose: SkyPose(aim: .init(azimuthDegrees: target.azimuthDegrees, altitudeDegrees: target.altitudeDegrees)),
                        selectedStarID: id, bundle: bundle)
                        .frame(height: 280).nightPanel()
                }
                statusRow(current, bundle: bundle)
                statusRow(staleStop, bundle: bundle)
                DirectionDiagnosticDetails(current: current, lastStop: staleStop, build: "7", bundle: bundle)
                    .padding(12)
                    .nightPanel()
            }
            .padding(16)
            .frame(width: 360)
            .foregroundStyle(Color.hsText)
            .background(Color.hsNight)
            .environment(\.locale, Locale(identifier: language))
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            guard let image = renderer.cgImage,
                  let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                fatalError("Could not render production readiness copy")
            }
            try data.write(to: outputURL.appendingPathComponent("readiness-\(language).png"))
        }
    }

    private static func diagnostic(
        rawAccuracy: Double, residual: Double, gravityError: Double,
        motionAge: TimeInterval, headingAge: TimeInterval, reference: HeadingReference,
        hasTrueHeading: Bool, magneticCalibrated: Bool, magneticKey: String
    ) -> DirectionDiagnosticSnapshot {
        let sensors = DirectionSensorSnapshot(
            uptime: 0, motionAge: motionAge, headingAge: headingAge,
            aim: DeviceAim(azimuthDegrees: 0, altitudeDegrees: 20), isMoving: false,
            rawAccuracy: rawAccuracy, residual: residual, gravityError: gravityError,
            reference: reference, hasTrueHeading: hasTrueHeading, magneticKey: magneticKey,
            magneticCalibrated: magneticCalibrated
        )
        let state = DirectionReadiness.evaluate(
            location: .available, directionHardwareAvailable: true,
            sensorIsFresh: sensors.motionIsFresh && sensors.aim != nil,
            headingAccuracyDegrees: sensors.assessment.effectiveAccuracyDegrees,
            targetAltitudeDegrees: 20, isMoving: sensors.isMoving,
            preparationHasTimedOut: false, headingIsFresh: sensors.headingIsFresh
        )
        return DirectionDiagnosticSnapshot(state: state, sensors: sensors)
    }

    private static func statusRow(_ diagnostic: DirectionDiagnosticSnapshot, bundle: Bundle) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: diagnostic.state.canConfirmAlignment ? "checkmark.circle.fill" : "info.circle")
                .foregroundStyle(Color.hsDiscovery)
            DirectionStatusCopy(state: diagnostic.state, bundle: bundle, overridePrefix: diagnostic.copyPrefix)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nightPanel()
    }
}
