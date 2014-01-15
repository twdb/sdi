import os
import unittest

import numpy as np

from sdi.pickfile import read

class TestReadMeta(unittest.TestCase):
    """ Test reading of metadata from binary files against values 
    seen in DepthPic GUI.
    """

    def setUp(self):
        self.test_dir = os.path.dirname(__file__)
        self.test_data = {
            '07050823':{'draft': 0.39624, #m
                'tide': 0.0, #m
                'speed_of_sound': 1491.996, #m/s
                'trace_numbers': [1, 1600, 3993],
                'convert_to_meters': 0.3048,
                'pre_depths': [7.47, 45.75, 27.93],
                'pic_depths': [6.15, 42.76, 24.70],
            },
            '09112301':{'draft': 0.4572, #m
                'tide': 0.0, #m
                'speed_of_sound': 1470.9648, #m/s
                'trace_numbers': [1, 1360, 1863],
                'convert_to_meters': 0.3048,
                'pre_depths': [14.76, 22.21, 13.61],
                'pic_depths': [13.39, 21.08, 12.21],
            },
            '09112303':{'draft': 0.4572, #m
                'tide': 0.0, #m
                'speed_of_sound': 1470.9648, #m/s
                'trace_numbers': [1, 72, 684],
                'convert_to_meters': 0.3048,
                'pre_depths': [9.74, 13.89, 12.27],
                'pic_depths': [9.09, 12.61, 11.04],
            },

        }


    def test_read_picks(self):
        """ Test pick file reader against test_data

        """

        for name, test_data in self.test_data.iteritems():
            for ext, surface_number in zip(['pic', 'pre'],[1, 2]):
                    filename = os.path.join(self.test_dir, 'files', name + '.' + ext)
                    print 'testing %s' % filename
                    data = read(filename)
                    self.assertAlmostEqual(data['draft'], test_data['draft'], places=4)
                    self.assertAlmostEqual(data['tide'], test_data['tide'], places=4)
                    self.assertAlmostEqual(data['speed_of_sound'], test_data['speed_of_sound'], places=4)
                    self.assertEqual(data['surface_number'], surface_number)
                    for idx, value in zip(test_data['trace_numbers'], test_data[ext+'_depths']):
                        self.assertAlmostEqual(data['depths'][idx-1], value*test_data['convert_to_meters'])


if __name__ == '__main__':
    unittest.main()