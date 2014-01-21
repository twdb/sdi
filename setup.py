"""
sdi
===

Reader for Speciality Devices Incorporated (SDI) depth sounder binary format
"""
from setuptools import setup

setup(
    name='sdi',
    version='0.1-dev',
    url='http://github.com/twdb/sdi',
    author='Dharhas Pothina and Andy Wilson',
    author_email='dharhas.pothina@twdb.texas.gov',
    description='A library for reading the SDI depth soundary binary format',
    long_description=__doc__,
    platforms='any',
    license='BSD',
    install_requires=[
        'numpy>=1.7',
    ],
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Science/Research',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Topic :: Software Development :: Libraries :: Python Modules'
    ],
)
