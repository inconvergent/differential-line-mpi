# -*- coding: utf-8 -*-
# cython: profile=True

from __future__ import division

#cdef extern from 'mpi-compat.h': pass

from mpi4py cimport MPI
from mpi4py cimport mpi_c

cimport segments
from libc.stdlib cimport malloc, free

cdef struct s_All_Data:
  long vnum
  long enum
  long snum
ctypedef s_All_Data s_all_data

cdef class DifferentialLine(segments.Segments):

  cdef double nearl

  cdef double farl

  cdef double *LSX

  cdef double *LSY

  cdef double *LX

  cdef double *LY

  cdef long *vertices

  ## FUNCTIONS

  cdef long __distribute_zonemap(self) nogil

  cdef void __encode_topology(self, long *a, double *b) nogil

  cdef void __decode_topology(self, long *a, double *b) nogil

  cdef void __distribute_data(self) nogil

  cdef void __dist_counts(self, int *dist_counts, int *dist_displ) nogil

  cdef long __reject(
    self,
    long v,
    long local_v,
    long *vertices,
    long num,
    double step,
    double *sx,
    double *sy
  ) nogil

  cpdef long optimize_position(self, double step)

