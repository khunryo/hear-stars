"""Internal coefficient/fixture smoke check; not an independent SOFA oracle."""

from __future__ import annotations

import math

PI = math.pi
ARCSEC = PI / (180.0 * 3600.0)
JD_UTC = 2461056.0
JD_TT = JD_UTC + 69.184 / 86400.0
T = (JD_TT - 2451545.0) / 36525.0


def polynomial(*coefficients: float) -> float:
    result = 0.0
    for coefficient in reversed(coefficients):
        result = result * T + coefficient
    return result


def multiply(left: list[list[float]], right: list[list[float]]) -> list[list[float]]:
    return [[sum(left[i][k] * right[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def apply(matrix: list[list[float]], vector: tuple[float, float, float]) -> tuple[float, float, float]:
    return tuple(sum(matrix[i][k] * vector[k] for k in range(3)) for i in range(3))  # type: ignore[return-value]


def r1(angle: float) -> list[list[float]]:
    c, s = math.cos(angle), math.sin(angle)
    return [[1, 0, 0], [0, c, s], [0, -s, c]]


def r3(angle: float) -> list[list[float]]:
    c, s = math.cos(angle), math.sin(angle)
    return [[c, s, 0], [-s, c, 0], [0, 0, 1]]


gamb = polynomial(-0.052928, 10.556378, 0.4932044, -0.00031238, -0.000002788, 0.0000000260) * ARCSEC
phib = polynomial(84381.412819, -46.811016, 0.0511268, 0.00053289, -0.000000440, -0.0000000176) * ARCSEC
psib = polynomial(-0.041775, 5038.481484, 1.5584175, -0.00018522, -0.000026452, -0.0000000148) * ARCSEC
epsa = polynomial(84381.406, -46.836769, -0.0001831, 0.00200340, -0.000000576, -0.0000000434) * ARCSEC
matrix = multiply(multiply(multiply(r1(-epsa), r3(-psib)), r1(phib)), r3(gamb))

d = JD_UTC - 2451545.0
era = (2 * PI * (0.7790572732640 + 1.00273781191135448 * d)) % (2 * PI)
p = polynomial(0.014506, 4612.156534, 1.3915817, -0.00000044, -0.000029956, -0.0000000368)
gmst = (era + p * ARCSEC) % (2 * PI)

assert math.isclose(math.degrees(gmst), 294.952729443, abs_tol=1e-9)

fixtures = [
    (37.95456067, 89.26410897, 46.476709119, 89.371738133),
    (101.28715533, -16.71611586, 101.578086872, -16.744851937),
    (88.79293899, 7.40706400, 89.145423437, 7.409668022),
    (279.23473479, 38.78368896, 279.453392796, 38.807228030),
]
for ra_degrees, dec_degrees, expected_ra, expected_dec in fixtures:
    ra, dec = math.radians(ra_degrees), math.radians(dec_degrees)
    transformed = apply(matrix, (math.cos(dec) * math.cos(ra), math.cos(dec) * math.sin(ra), math.sin(dec)))
    actual_ra = math.degrees(math.atan2(transformed[1], transformed[0])) % 360
    actual_dec = math.degrees(math.atan2(transformed[2], math.hypot(transformed[0], transformed[1])))
    assert math.isclose(actual_ra, expected_ra, abs_tol=1e-9)
    assert math.isclose(actual_dec, expected_dec, abs_tol=1e-9)

print("Reference fixtures: OK")
