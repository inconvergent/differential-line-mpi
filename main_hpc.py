#!/usr/bin/python
# -*- coding: utf-8 -*-

from mpi4py import MPI


NMAX = 10**7
PREFIX = './res/export'
SIZE = 20000
STP = 0.5
NEARL = 4.0
FARL = 200.0
PROCS = 4
STAT_ITT = 100
EXPORT_ITT = 200
NINIT = 20
RAD = 0.05


def main():

  from time import time
  from itertools import count

  from numpy import pi
  from numpy.random import random

  from modules.growth import spawn_curl
  from modules.utils import get_exporter
  from modules.helpers import env_or_default
  from modules.helpers import print_stats

  from differentialLine import DifferentialLine


  comm = MPI.COMM_WORLD
  nodes = comm.Get_size()
  rank = comm.Get_rank()

  if rank == 0:

    size = env_or_default('SIZE', SIZE)
    nmax = env_or_default('NMAX', NMAX)
    one = 1.0/size

    export_itt = env_or_default('EXPORT_ITT', EXPORT_ITT)
    stat_itt = env_or_default('STAT_ITT', STAT_ITT)

    data = {
      'size': size,
      'nmax': nmax,
      'vmax': env_or_default('VMAX', NMAX),
      'procs': env_or_default('PROCS', PROCS),
      'nodes': nodes,
      'prefix': env_or_default('PREFIX', PREFIX),
      'ninit': env_or_default('NINIT', NINIT),
      'rad': env_or_default('RAD', RAD),
      'one': one,
      'stp': env_or_default('STP', STP)*one,
      'nearl': env_or_default('NEARL', NEARL)*one,
      'farl': env_or_default('FARL', FARL)*one
    }

  else:
    data = None

  data = comm.bcast(data, root=0)

  DF = DifferentialLine(
    data['nmax'],
    zonewidth = data['farl'],
    nearl = data['nearl'],
    farl = data['farl'],
    procs = data['procs'],
    nodes = data['nodes']
  )

  if rank == 0:

    angles = sorted(random(data['ninit'])*pi*2)

    DF.init_circle_segment(0.5, 0.5, data['rad'], angles)

    t_start = time()
    do_export = get_exporter(nmax, t_start)

  for i in count():

    DF.optimize_position(data['stp'])

    if DF.get_vnum()>data['vmax']:
      if rank == 0:
        do_export(DF, data, i, final=True)
      return

    if rank == 0:

      spawn_curl(DF,data['nearl'])

      if i % stat_itt == 0:
        print_stats(i,time()-t_start,DF)
      if i % export_itt == 0:
          do_export(DF, data, i)


if __name__ == '__main__':

  main()

