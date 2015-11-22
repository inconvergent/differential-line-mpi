#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function

def env_or_default(name, d):

  from os import environ

  try:
    a = environ[name]
    if a:
      return type(d)(a)
    else:
      return d
  except Exception:
    return d

def print_stats(steps, t_diff, dl):

  from time import strftime

  print(
    '{:s} | stp: {:d} time: {:.5f} v: {:d} e: {:d}'.format(
      strftime('%d/%m/%Y %H:%M:%S'),
      steps,
      t_diff,
      dl.get_vnum(),
      dl.get_enum()
    )
  )

  return

