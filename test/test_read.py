import os
import unittest

import numpy as np

from sdi.binary import Dataset


class TestRead(unittest.TestCase):
    """ Test basic reading of binary files
    """

    def setUp(self):
        self.test_dir = os.path.dirname(__file__)

    def test_read(self):
        """ Test that all test files can be read without errors """
        for root, dirs, files in os.walk(os.path.join(self.test_dir, 'files')):
            for filename in files:
                if filename.endswith('.bin'):
                    d = Dataset(os.path.join(root, filename))
                    data = d.as_dict()
                    for freq in data['frequencies'].keys():
                        x = data['frequencies'][freq]['utm_x']
                        y = data['frequencies'][freq]['utm_y']
                        image = data['frequencies'][200.0]['intensity']
                        self.assertIsInstance(x, np.ndarray)
                        self.assertIsInstance(y, np.ndarray)
                        self.assertIsInstance(image, np.ndarray)

    def test_fill_nans(self):
        """ Test for "IndexError: tuple index out of range"
        """
        filename = os.path.join(self.test_dir, 'files', '07050823.bin')
        d = Dataset(filename)
        data = d.as_dict()

    def test_overflowerror(self):
        """ Test for "OverflowError: Python int too large to convert to C long"
        """
        filename = os.path.join(self.test_dir, 'files', '09062409.bin')
        d = Dataset(filename)
        data = d.as_dict()

    def test_discontinuity(self):
        """ Test for "IndexError: index out of bounds"
        """
        filename = os.path.join(self.test_dir, 'files', '08091852.bin')
        d = Dataset(filename)
        data = d.as_dict()


if __name__ == '__main__':
    unittest.main()
