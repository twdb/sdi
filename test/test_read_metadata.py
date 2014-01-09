import os
import unittest
from datetime import date

import numpy as np

from sdi.binary import read

class TestReadMeta(unittest.TestCase):
    """ Test reading of metadata from binary files against values 
    seen in DepthPic GUI.
    """

    def setUp(self):
        self.test_dir = os.path.dirname(__file__)
        self.test_data = {
           '06081001.bin':{'draft': 0.37, 
                'tide': 0.0, 
                'spdos': 1477.1,
                'date': date(2006, 8, 10),
            },
           '07050823.bin':{'draft': 0.40, 
                'tide': 0.0, 
                'spdos': 1492.0,
                'date': date(2007,5,8)
            },
            '08091852.bin':{'draft': 0.46, 
                'tide': 0.0, 
                'spdos': 1499.3,
                'date': date(2008,9,18)
            },
            '09112303.bin':{'draft': 0.46, 
                'tide': 0.0, 
                'spdos': 1471.0,
                'date': date(2009,11,23)
            },
        }

    def test_read_metadata(self):
        """ Test that metadata matches what can be seen in DepthPic GUI. 
        Note: Only a limited number of fields are visible in DepthPic.
        """

        for name, metadata in self.test_data.iteritems():
            filename = os.path.join(self.test_dir, 'files', name)
            d = read(filename)
            f200 = max(d['frequencies'].keys())
            
            self.assertEqual(d['date'], metadata['date'])
            self.assertAlmostEqual(np.unique(d['frequencies'][f200]['draft']), metadata['draft'], places=2)
            self.assertAlmostEqual(np.round(np.unique(d['frequencies'][f200]['spdos']),1), metadata['spdos'], places=1)
            self.assertAlmostEqual(np.unique(d['frequencies'][f200]['tide']), metadata['tide'], places=2)


if __name__ == '__main__':
    unittest.main()