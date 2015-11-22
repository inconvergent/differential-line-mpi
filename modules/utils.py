# -*- coding: utf-8 -*-

def get_exporter(nmax, t_start):

  from dddUtils.ioOBJ import export_2d as export_obj
  from time import time
  from numpy import zeros

  verts = zeros((nmax, 2),'double')

  def f(df, data, itt, final=False):

    if final:
      fn = '{:s}_final.2obj'.format(data['prefix'])
    else:
      fn = '{:s}_{:010d}.2obj'.format(data['prefix'],itt)

    num = df.np_get_sorted_vert_coordinates(verts)
    meta = '\n# procs {:d}\n# vnum {:d}\n# time {:f}\n# nearl {:f}\n# farl {:f}\n# stp {:f}\n size {:d}'.format(
      data['procs'],
      num,
      time()-t_start,
      data['nearl'],
      data['farl'],
      data['stp'],
      data['size']
    )
    export_obj('line',fn, verts[:num,:], meta=meta)

  return f

