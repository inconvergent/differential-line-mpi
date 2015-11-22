#!/usr/bin/python

try:
  from setuptools import setup
  from setuptools.extension import Extension
except Exception:
  from distutils.core import setup
  from distutils.extension import Extension

from modules.helpers import env_or_default

from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy
import mpi4py

_extra = [
  '-fopenmp' ,
  '-lmpi',
  '-ldl',
  '-lhwloc',
  '-O3',
  '-ffast-math'
]

install_requires = [
  'numpy==1.8.2',
  'cython>=0.20.0',
  'mpi4py==1.3.1'
]

include_dirs = env_or_default(
  'MPI_INCLUDES',
  '/usr/lib/openmpi/include;/usr/lib/openmpi/include/openmpi'
).split(';') + [
  numpy.get_include(),
  mpi4py.get_include()
]

_extra_link_args = [
  '-fopenmp',
  '-lmpi'
]

print(include_dirs)

extensions = [
  Extension('segments',
            sources = ['./src/segments.pyx'],
            extra_compile_args = _extra,
            extra_link_args = _extra_link_args
  ),
  Extension('differentialLine',
            sources = ['./src/differentialLine.pyx'],
            extra_compile_args = _extra,
            extra_link_args = _extra_link_args
  )
]

setup(
  name = "differential-line",
  version = '0.0.4',
  author = '@inconvergent',
  install_requires = install_requires,
  license = 'MIT',
  cmdclass={'build_ext' : build_ext},
  include_dirs = include_dirs,
  ext_modules = cythonize(
    extensions,
    include_path = include_dirs
  )
)

