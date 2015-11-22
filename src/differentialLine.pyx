# -*- coding: utf-8 -*-
# cython: profile=True

from __future__ import division

cimport cython

from mpi4py cimport MPI
from mpi4py cimport mpi_c


cimport segments

from cython.parallel import parallel, prange

from libc.math cimport sqrt
from libc.math cimport ceil


from helpers cimport double_array_init
from helpers cimport long_array_init
from helpers cimport edges_are_connected

from zonemap cimport Zonemap


cdef class DifferentialLine(segments.Segments):

  def __init__(
    self,
    long nmax,
    double zonewidth,
    double nearl,
    double farl,
    long procs,
    long nodes
  ):

    segments.Segments.__init__(
      self,
      nmax,
      zonewidth,
      procs,
      nodes
    )

    """
    - nearl is the closest comfortable distance between two vertices.

    - farl is the distance beyond which disconnected vertices will ignore
    each other
    """

    self.nearl = nearl

    self.farl = farl

    if self.rank == 0:

      print('nearl: {:f}'.format(nearl))
      print('farl: {:f}'.format(farl))

    return

  def __cinit__(self, long nmax, *arg, **args):

    self.LSX = <double *>malloc(nmax*sizeof(double))

    self.LSY = <double *>malloc(nmax*sizeof(double))

    self.LX = <double *>malloc(nmax*sizeof(double))

    self.LY = <double *>malloc(nmax*sizeof(double))

    self.vertices = <long *>malloc(nmax*sizeof(long))

    return

  def __dealloc__(self):

    free(self.LSX)

    free(self.LSY)

    free(self.vertices)

    return

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.cdivision(True)
  cdef long __reject(
    self,
    long v,
    long local_v,
    long *vertices,
    long num,
    double step,
    double *sx,
    double *sy
  ) nogil:

    """
    all vertices will move away from all neighboring (closer than farl)
    vertices
    """

    cdef double dx
    cdef double dy
    cdef double nrm

    if self.VA[v]<1:
      return -1

    cdef long e1 = self.VE[2*v]
    cdef long e2 = self.VE[2*v+1]

    cdef long v1
    cdef long v2

    # connected vertices to v, v1 and v2

    if self.EV[2*e1] == v:
      v1 = self.EV[2*e1+1]
    else:
      v1 = self.EV[2*e1]

    if self.EV[2*e2] == v:
      v2 = self.EV[2*e2+1]
    else:
      v2 = self.EV[2*e2]

    cdef double resx = 0.
    cdef double resy = 0.

    cdef long neigh
    cdef long k

    for k in range(num):

      neigh = vertices[k]
      dx = self.X[v]-self.X[neigh]
      dy = self.Y[v]-self.Y[neigh]
      nrm = sqrt(dx*dx+dy*dy)

      if neigh == v1 or neigh == v2:
        # linked

        if nrm<self.nearl or nrm<=0.:
          continue

        resx += -dx/nrm*step
        resy += -dy/nrm*step

      else:
        # not linked

        if nrm>self.farl or nrm<=0.:
          continue

        resx += dx*(self.farl/nrm-1)*step
        resy += dy*(self.farl/nrm-1)*step

    sx[local_v] += resx
    sy[local_v] += resy

    return 1

  #@cython.wraparound(False)
  #@cython.boundscheck(False)
  #@cython.nonecheck(False)
  #cdef long __distribute_data(self):

    ## TODO: define mpi data structure

    #cdef mpi_c.MPI_Datatype datatype

    #cdef int counts[4]
    #counts[0] = 1
    #counts[1] = 1
    #counts[2] = 1
    #counts[3] = 1

    #cdef mpi_c.MPI_Aint offsets[4]
    #offsets[0] = <Py_ssize_t>&(<s_all_data*>NULL).vnum
    #offsets[1] = <Py_ssize_t>&(<s_all_data*>NULL).enum
    #offsets[2] = <Py_ssize_t>&(<s_all_data*>NULL).snum

    #cdef mpi_c.MPI_Datatype[4] types
    #types[0] = mpi_c.MPI_LONG
    #types[1] = mpi_c.MPI_LONG
    #types[2] = mpi_c.MPI_LONG
    #types[3] = mpi_c.MPI_LONG

    #mpi_c.MPI_Type_create_struct(4, counts, offsets, types, &datatype)
    #mpi_c.MPI_Type_commit(&datatype)

    #cdef s_all_data *all_data = <s_all_data *>malloc(sizeof(s_all_data))

    #if self.rank == 0:
      #all_data.vnum = self.vnum
      #all_data.enum = self.enum
      #all_data.snum = self.snum

    #mpi_c.MPI_Bcast(all_data, 1, datatype, 0, self.comm)

    #if self.rank != 0:
      #self.vnum = all_data.vnum
      #self.enum = all_data.enum
      #self.snum = all_data.snum

    #mpi_c.MPI_Type_free(&datatype);

    ## mpi_c.MPI_Bcast(&self.vnum, 1, mpi_c.MPI_LONG, 0, self.comm)
    ## mpi_c.MPI_Bcast(&self.enum, 1, mpi_c.MPI_LONG, 0, self.comm)
    ## mpi_c.MPI_Bcast(&self.snum, 1, mpi_c.MPI_LONG, 0, self.comm)

    #mpi_c.MPI_Bcast(self.X, self.vnum, mpi_c.MPI_DOUBLE, 0, self.comm)
    #mpi_c.MPI_Bcast(self.Y, self.vnum, mpi_c.MPI_DOUBLE, 0, self.comm)
    #mpi_c.MPI_Bcast(self.VA, self.vnum, mpi_c.MPI_LONG, 0, self.comm)
    #mpi_c.MPI_Bcast(self.VS, self.vnum, mpi_c.MPI_LONG, 0, self.comm)
    #mpi_c.MPI_Bcast(self.EV, 2*self.enum, mpi_c.MPI_LONG, 0, self.comm)
    #mpi_c.MPI_Bcast(self.VE, 2*self.vnum, mpi_c.MPI_LONG, 0, self.comm)

    #return 1

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  cdef void __encode_topology(self, long *a, double *b) nogil:

    cdef long i
    cdef long offset = 0

    for i in xrange(self.vnum):
      a[i] = self.VA[i]
    offset = self.vnum

    for i in xrange(self.vnum):
      a[offset+i] = self.VS[i]
    offset += self.vnum

    for i in xrange(2*self.enum):
      a[offset+i] = self.EV[i]
    offset += 2*self.enum

    for i in xrange(2*self.vnum):
      a[offset+i] = self.VE[i]

    offset = 0
    for i in xrange(self.vnum):
      b[i] = self.X[i]
    offset = self.vnum

    for i in xrange(self.vnum):
      b[offset+i] = self.Y[i]

    return

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  cdef void __decode_topology(self, long *a, double *b) nogil:

    cdef long i
    cdef long offset = 0

    for i in xrange(self.vnum):
      self.VA[i] = a[i]
    offset = self.vnum

    for i in xrange(self.vnum):
      self.VS[i] = a[offset+i]
    offset += self.vnum

    for i in xrange(2*self.enum):
      self.EV[i] = a[offset+i]
    offset += 2*self.enum

    for i in xrange(2*self.vnum):
      self.VE[i] = a[offset+i]

    offset = 0
    for i in xrange(self.vnum):
      self.X[i] = b[i]
    offset = self.vnum

    for i in xrange(self.vnum):
      self.Y[i] = b[offset+i]

    return

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  cdef void __distribute_data(self) nogil:

    cdef long *meta = <long *>malloc(3*sizeof(long))

    if self.rank == 0:
      meta[0] = self.vnum
      meta[1] = self.enum
      meta[2] = self.snum

    mpi_c.MPI_Bcast(meta, 3, mpi_c.MPI_LONG, 0, self.comm)

    if self.rank != 0:
      self.vnum = meta[0]
      self.enum = meta[1]
      self.snum = meta[2]

    cdef long topo_count = 4*self.vnum+2*self.enum
    cdef long *topo = <long *>malloc(topo_count*sizeof(long))
    cdef double *xy = <double *>malloc(self.vnum*2*sizeof(double))
    self.__encode_topology(topo,xy)

    mpi_c.MPI_Bcast(xy, 2*self.vnum, mpi_c.MPI_DOUBLE, 0, self.comm)
    mpi_c.MPI_Bcast(topo, topo_count, mpi_c.MPI_LONG, 0, self.comm)

    if self.rank != 0:
      self.__decode_topology(topo,xy)

    free(meta)
    free(topo)
    free(xy)

    return

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  cdef long __distribute_zonemap(self) nogil:
    """
    first you must run __distribute_data()
    """

    cdef long *encoded
    cdef long es

    if self.rank == 0:
      es = self.zonemap.__get_encode_zonemap_max_size()
    mpi_c.MPI_Bcast(&es, 1, mpi_c.MPI_LONG, 0, self.comm)

    encoded = <long *>malloc(es*sizeof(long))

    if self.rank == 0:
      self.zonemap.__encode_zonemap(encoded)
    mpi_c.MPI_Bcast(encoded, es, mpi_c.MPI_LONG, 0, self.comm)

    if self.rank > 0:
      self.zonemap.__decode_zonemap(encoded)
    free(encoded)

    return 1

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.cdivision(True)
  cdef void __dist_counts(self, int *dist_counts, int *dist_displ) nogil:

    cdef long d = 0
    cdef long c
    cdef long p
    for p in xrange(self.nodes):

      c = <int>ceil(<double>self.vnum/<double>self.nodes)
      if c*(p+1)>self.vnum:
        c = self.vnum-d

      dist_counts[p] = c
      d += c

    d = 0
    for p in xrange(self.nodes):

      dist_displ[p] = d
      d += dist_counts[p]

    return

  @cython.wraparound(False)
  @cython.boundscheck(False)
  @cython.nonecheck(False)
  @cython.cdivision(True)
  cpdef long optimize_position(self, double step):

    cdef long *vertices
    cdef long v
    cdef long local_v
    cdef long num

    if self.nodes>1:
      self.__distribute_data()
      self.__distribute_zonemap()

    cdef long asize = self.zonemap.__get_max_sphere_count()*sizeof(long)
    cdef int *v_dist_count = <int *>malloc(self.nodes*sizeof(int))
    cdef int *v_dist_displ = <int *>malloc(self.nodes*sizeof(int))

    self.__dist_counts(v_dist_count, v_dist_displ)

    with nogil, parallel(num_threads=self.procs):

      vertices = <long *>malloc(asize)

      for local_v in prange(v_dist_count[self.rank], schedule='static'):

        v = v_dist_displ[self.rank] + local_v

        self.LSX[local_v] = 0.0
        self.LSY[local_v] = 0.0

        if self.VA[v]<0:
          continue

        num = self.zonemap.__sphere_vertices(
          self.X[v],
          self.Y[v],
          self.farl,
          vertices
        )
        self.__reject(
          v,
          local_v,
          vertices,
          num,
          step,
          self.LSX,
          self.LSY
        )

      free(vertices)

      for local_v in prange(v_dist_count[self.rank], schedule='static'):

        v = v_dist_displ[self.rank] + local_v

        self.LX[local_v] = self.X[v]
        self.LY[local_v] = self.Y[v]

        if self.VA[v]<0:
          continue

        self.LX[local_v] += self.LSX[local_v]
        self.LY[local_v] += self.LSY[local_v]

    with nogil:

      mpi_c.MPI_Gatherv(
        self.LX,
        v_dist_count[self.rank],
        mpi_c.MPI_DOUBLE,
        self.X,
        v_dist_count,
        v_dist_displ,
        mpi_c.MPI_DOUBLE,
        0,
        self.comm
      )
      mpi_c.MPI_Gatherv(
        self.LY,
        v_dist_count[self.rank],
        mpi_c.MPI_DOUBLE,
        self.Y,
        v_dist_count,
        v_dist_displ,
        mpi_c.MPI_DOUBLE,
        0,
        self.comm
      )

    if self.rank == 0:

      with nogil:

        for v in range(self.vnum):
          if self.VA[v]<0:
            continue

          self.zonemap.__update_v(v)

