
from datetime import datetime
import numpy as np
import struct
from StringIO import StringIO

class Dataset(object):
    def __init__(self, filename):
        self.filename = filename

        with open(filename, 'rb') as fid:
            data = fid.read()

        fid = StringIO(data)
        self.survey_line_number = struct.unpack('<8s', data[:8])[0]
        self.version = _version(data[10])
        if self.version <= 3.2:
            raise NotImplementedError, 'Reading of file formats <= 3.2 Not Supported, File Version=' + str(version)

        self.resolution_cm = int(ord(data[11])) 
        self.date = datetime.strptime(self.survey_line_number[:6], '%y%m%d').date()  

        dtype, extended_dtype = _dtype(self.version)
        trace_metadata = {}
        # intitialize trace lists
        for field, fmt in dtype + extended_dtype:
            trace_metadata[field] = []

        trace_metadata['event'] = []
        trace_intensity = []
        npos = 12
        fid.seek(npos)
        while npos<len(data):
            for field, fmt in dtype:
                size = struct.calcsize(fmt)
                trace_metadata[field].append(struct.unpack(fmt, fid.read(size))[0])

            size = trace_metadata['event_len'][-1]
            trace_metadata['event'].append(struct.unpack('<'+str(size)+'s',fid.read(size))[0])

            for field, fmt in extended_dtype:
                size = struct.calcsize(fmt)
                trace_metadata[field].append(struct.unpack(fmt, fid.read(size))[0])

            fid.seek(npos + trace_metadata['offset'][-1]+2)
            size = trace_metadata['num_pnts'][-1]
            trace_intensity.append(np.array(struct.unpack('<' + str(size)+ 'H',fid.read(size*2)))) 
            npos = int(fid.tell())

        self.trace_metadata = trace_metadata
        self.trace_intensity = trace_intensity

def _version(version_hex):
    return float(str(ord(version_hex) >> 4) + '.' + str(ord(version_hex) & 0xF))


def _dtype(version):
    dtype = [
        ('offset', '<H'),
        ('trace_num', '<l'),
        ('units', '<B'),
        ('spdos_units', '<B'),
        ('spdos', '<h'),
        ('min_window10', '<h'),
        ('max_window10', '<h'),
        ('draft100', '<h'),
        ('tide100', '<h'),
        ('heave_cm', '<h'),
        ('display_range', '<h'),
        ('depth_r1', '<f'),
        ('min_pnt_r1', '<f'),
        ('num_pnt_r1', '<f'),
        ('blanking_pnt', '<h'),
        ('depth_pnt','<h'),
        ('range_pnt','<h'),
        ('num_pnts','<h'),
        ('clock', '<l'),
        ('hour', '<B'),
        ('min', '<B'),
        ('sec', '<B'),
        ('sec100', '<B'),
        ('rate', '<l'),
        ('kHz', '<f'),
        ('event_len', '<B'),
    ]

    extended_dtype = [
        ('latitude', '<2d'),
        ('longitude', '<2d'),
        ('transducer', '<B'),
        ('options', '<B'),
        ('data_offset', '<B'),
    ]

    if version >= 3.3:
        extended_dtype.append(('utm_x', '<2d'))
        extended_dtype.append(('utm_y', '<2d'))

    if version >= 4.0:
        extended_dtype.append(('cycles', '<B'))
        extended_dtype.append(('volts', '<B'))
        extended_dtype.append(('power', '<B'))
        extended_dtype.append(('gain', '<B'))
        extended_dtype.append(('previous_offset', '<H'))

    if version >= 4.2:
        extended_dtype.append(('antenna_e1', '<4f'))
        extended_dtype.append(('antenna_ht', '<4f'))
        extended_dtype.append(('draft', '<4f'))
        extended_dtype.append(('tide', '<4f'))

    if version >= 4.3:
        extended_dtype.append(('gps_mode', '<B'))
        extended_dtype.append(('hdop', '<f'))

    return dtype, extended_dtype