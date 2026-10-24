import unittest
from import_full_sky import coordinate, nearest_star, merge_constellation_id


class ImportFullSkyTests(unittest.TestCase):
    def test_j2000_hours_and_negative_declination(self):
        row = {'RAh': '06', 'RAm': '45', 'RAs': '08.9',
               'DE-': '-', 'DEd': '16', 'DEm': '42', 'DEs': '58'}
        result = coordinate(row)
        self.assertIsNotNone(result)
        self.assertAlmostEqual(result[0], 101.2870833333, places=8)
        self.assertAlmostEqual(result[1], -16.7161111111, places=8)

    def test_north_pole_and_zero_hours(self):
        self.assertEqual(coordinate({'RAh': '00', 'RAm': '00', 'RAs': '00',
                                    'DE-': '+', 'DEd': '90', 'DEm': '00', 'DEs': '00'}), (0, 90))

    def test_invalid_missing_coordinate_is_rejected(self):
        self.assertIsNone(coordinate({'RAh': '00'}))

    def test_nearest_match_crosses_ra_wrap(self):
        stars = [{'id': 'near', 'ra': 359.999, 'dec': 0}, {'id': 'far', 'ra': 10, 'dec': 0}]
        self.assertEqual(nearest_star((0.001, 0), stars, max_degrees=0.01), 'near')

    def test_distant_endpoint_is_not_silently_invented(self):
        self.assertIsNone(nearest_star((90, 0), [{'id': 'a', 'ra': 0, 'dec': 0}], max_degrees=0.02))

    def test_serpens_halves_are_one_constellation(self):
        self.assertEqual(merge_constellation_id('Ser1'), 'ser')
        self.assertEqual(merge_constellation_id('Ser2'), 'ser')
        self.assertEqual(merge_constellation_id('Ori'), 'ori')


if __name__ == '__main__':
    unittest.main()
