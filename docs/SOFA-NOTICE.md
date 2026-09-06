# IAU SOFA provenance notice

`Sources/HearStarsCore/AstronomyCalculator.swift` is a clean Swift
reimplementation of computations described by the IAU Standards of Fundamental
Astronomy (SOFA), principally GMST06 and the Fukushima–Williams P03
bias-precession formulation. It does **not** constitute software supplied or
endorsed by the IAU SOFA Board.

The Phase 1 implementation differs from the complete SOFA observing chain: it
uses `Foundation.Date`, assumes UT1 approximately equals UTC, uses a fixed
TT−UTC offset for the present validation epoch, applies catalog proper motion,
and omits nutation, aberration, parallax, radial velocity, and atmospheric
refraction. Those omissions and their release gates are detailed in
`ASTRONOMY-VALIDATION.md`.

The official license permits commercial use and adaptations subject to its
conditions, including clear derived-work provenance and non-endorsement:

- IAU SOFA, “Terms and Conditions”: https://www.iausofa.org/terms-and-conditions

Before a public build, recheck the current official terms and retain this notice
with the source and product acknowledgements.
