import unittest

import numpy as np
from numpy import nan

from sdi.binary import Dataset


class TestBuildIntensityImage(unittest.TestCase):
    """ Test build_intensity_image() method
    """

    def test_uniform_length(self):
        """Test that build_intensity_images works when the trace intensity
        tuples are of uniform length.
        """
        trace_intensities = [
            (0, 1, 2, 3),
            (4, 5, 6, 7),
            (8, 9, 10, 11),
        ]

        expected_image = np.array([
            (0, 1, 2, 3),
            (4, 5, 6, 7),
            (8, 9, 10, 11),
        ], dtype=np.float)

        d = Dataset(None)
        image = d.build_intensity_image(trace_intensities)

        np.testing.assert_allclose(image, expected_image)

    def test_increasing(self):
        """Test that build_intensity_images works when the trace intensities
        increase in length.
        """
        trace_intensities = [
            (0,  1),
            (4,  5),
            (8,  9,  10),
            (12, 13, 14),
            (16, 17, 18, 19),
            (21, 22, 23, 24),
        ]

        expected_image = np.array([
            (0, 1,   nan, nan),
            (4, 5,   nan, nan),
            (8, 9,   10,  nan),
            (12, 13, 14,  nan),
            (16, 17, 18,  19),
            (21, 22, 23,  24),
        ])

        d = Dataset(None)
        image = d.build_intensity_image(trace_intensities)
        np.testing.assert_allclose(image, expected_image)

    def test_decreasing(self):
        """Test that build_intensity_images works when the trace intensities
        decrease in length.
        """
        trace_intensities = [
            (0,   1,  2,  3),
            (4,   5,  6,  7),
            (8,   9, 10),
            (12, 13, 14),
            (16, 17),
            (21, 22),
        ]

        expected_image = [
            (0,   1,   2,   3),
            (4,   5,   6,   7),
            (8,   9,  10, nan),
            (12, 13,  14, nan),
            (16, 17, nan, nan),
            (21, 22, nan, nan),
        ]

        d = Dataset(None)
        image = d.build_intensity_image(trace_intensities)
        np.testing.assert_allclose(image, expected_image)

    def test_ragged(self):
        """Test that build_intensity_images works when the trace intensities
        are all over the place.
        """
        trace_intensities = [
            (0,   1,  2),
            (4,   5,  6,  7),
            (8,   9),
            (12, 13, 14, 15),
            (16,),
            (21, 22, 23),
        ]

        expected_image = [
            (0,    1,   2, nan),
            (4,    5,   6,   7),
            (8,    9, nan, nan),
            (12,  13,  14, 15),
            (16, nan, nan, nan),
            (21, 22,   23, nan),
        ]

        d = Dataset(None)
        image = d.build_intensity_image(trace_intensities)
        np.testing.assert_allclose(image, expected_image)


if __name__ == '__main__':
    unittest.main()
