import os
import unittest
from datetime import date
import json

import numpy as np

from sdi.binary import read, Dataset

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

        #precision of testing for float fields
        self.precision = {
            'num_pnt_r1': 2,
            'tide': 2,
            'max_window': 2,
            'draft': 2,
            'latitude': 6,
            'longitude': 6,
            'min_window': 2,
            'min_pnt_r1': 2,
            'kHz': 0,
            'utm_x': 6,
            'utm_y': 6,
            'depth_r1': 2,
            'pixel_resolution': 6,
            'spdos': 4, 
        }


    def test_read_metadata_against_depthpic(self):
        """ Test that metadata matches what can be seen in DepthPic GUI. 
        Note: Only a limited number of fields are visible in DepthPic.
        """

        for name, metadata in self.test_data.iteritems():
            filename = os.path.join(self.test_dir, 'files', name)
            d = read(filename)
            f200 = max(d['frequencies'].keys())
            print 'testing %s against DepthPic' % (filename)
            self.assertEqual(d['date'], metadata['date'])
            self.assertAlmostEqual(np.unique(d['frequencies'][f200]['draft']), metadata['draft'], places=2)
            self.assertAlmostEqual(np.round(np.unique(d['frequencies'][f200]['spdos']),1), metadata['spdos'], places=1)
            self.assertAlmostEqual(np.unique(d['frequencies'][f200]['tide']), metadata['tide'], places=2)


    def test_read_metadata_against_json(self):
        """ Test that metadata against selected values exported from the 
        binary files using the depreciated reader in pyhat 
        (https://github.com/twdb/pyhat). The pyhat reader has been in use 
        for several years and in the absense of an absolute way to test 
        the reader this is a reasonable sanity check.
        """

        for root, dirs, files in os.walk(os.path.join(self.test_dir, 'files')):
            for filename in files:
                if filename.endswith('.bin'):
                    jsonfile = os.path.join(root, filename.replace('.bin','.json'))
                    with open(jsonfile) as f:
                        j = json.load(f)

                    d = Dataset(os.path.join(root, filename))
                    d.parse()

                    print 'testing %s against %s' % (filename, jsonfile)
                    self.assertEqual(d.version, str(j['version']))
                    for a,b in zip(sorted(d.frequencies.keys()), sorted(j['frequencies'])):
                        self.assertAlmostEqual(a, b, places=0)

                    idx = j['index']
                    for field, value in j['data'].iteritems():
                        print 'testing %s' % field
                        data = d.trace_metadata[field][idx]
                        for a,b in zip(value, data):
                            if isinstance(a, int): 
                                self.assertEqual(a, b)

                            if isinstance(a, float):
                                self.assertAlmostEqual(a, b, places=self.precision[field])



if __name__ == '__main__':
    unittest.main()