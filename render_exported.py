#!/usr/bin/python
# -*- coding: utf-8 -*-

BACK = [1,1,1,1]
FRONT = [0,0,0,1]


def main(args):

  from dddUtils.ddd import get_mid_2d as get_mid
  from render.render import Render
  from dddUtils.ioOBJ import load
  from modules.show import show_closed

  from numpy import array

  data = load(args.fn)
  size = args.size

  if args.fill:
    fill = True
  else:
    fill = False

  one = 1.0/size
  vertices = data['vertices']

  print(vertices)

  if args.scale:

    vertices -= get_mid(vertices)
    vertices *= args.scale
    vertices += array([[0.5,0.5]])

  render = Render(size, BACK, FRONT)

  render.ctx.set_source_rgba(*FRONT)
  render.ctx.set_line_width(args.width*one)

  out = ''.join(args.fn.split('.')[:-1])+'.png'

  show_closed(render, vertices, out, fill=fill)

  #render.ctx.set_source_rgba(*[1,0,0,1])
  #for vv in vertices:
    #render.circle(vv[0], vv[1], one*4, fill=False)

  render.write_to_png(out)

  return

if __name__ == '__main__':

  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument(
    '--fn',
    type=str,
    required=True
  )
  parser.add_argument(
    '--fill',
    dest='fill',
    action='store_true'
  )
  parser.add_argument(
    '--no-fill',
    dest='fill',
    action='store_false'
  )
  parser.add_argument(
    '--width',
    type=float,
    default=1.0
  )
  parser.add_argument(
    '--size',
    type=int,
    default=10000
  )
  parser.add_argument(
    '--scale',
    type=float,
    default=None
  )

  args = parser.parse_args()

  print(args)

  main(args)

