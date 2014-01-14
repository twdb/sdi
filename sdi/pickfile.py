import numpy as np

def read(filename):
    """
    Reads in a DepthPic pick file and returns dict that contains
    the surface type, the speed of sound (m/s) and an arrays of depths 
    in meters and in pixels arranged by trace number. 

    To convert depths into pixel space use the following equation
    pixels_from_top_of_image = (depths - draft + tide)/pixel_resolution

    Note: We ignore position data and trace number fields as they are superfluous

    Format Example:
        Depth                                   <--- Always Depth (Possibly elevation in some setups, we don't have)
        2                                       <--- Surface Number (1=current, >2=preimpoundment)
        FEET                                    <--- Units of Depth
        1.48498560000000E+0003                  <--- Speed of Sound (m/s)
        4.57200000000000E-0001                  <--- Draft (m)
        0.00000000000000E+0000                  <--- Tide (m) 
        TRUE                                    <--- Not sure what this is?
        2                                       <--- 1/2/3/4 (1=northing/easting,2=lat/lon,3=0/distance,4=northin/easting)
        -97.90635230   28.06836280     4.33 1   <--- X Y Depth TraceNumber
        ...

    """

    data = {}

    units_factors = {
        'feet': 0.3048,  # feet to meters
        'meters': 1.0,  # meters to meters
        'fathoms': 1.8288,  # fathoms to meters
    }

    with open(filename) as f:
        f.readline()
        data['surface_number'] = int(f.readline().strip('r\n'))
        units = f.readline().strip('\r\n').lower()
        convert_to_meters = units_factors[units]
        data['speed_of_sound'] = float(f.readline().strip('\r\n')) #always in m/s
        data['draft'] = float(f.readline().strip('\r\n')) #always in m
        data['tide'] = float(f.readline().strip('\r\n')) #always in m
        data['flag'] = f.readline().strip('\r\n')
        position_type = f.readline().strip('\r\n') 
        if position_type=='3':
            col = 1
        else:
            col = 2
         
        data['depths'] = np.genfromtxt(f, usecols=[col], skiprows=3)*convert_to_meters

    return data
