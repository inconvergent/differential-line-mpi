Differential Line MPI
=============

## Note!

This repo is a fork of `differential-line`:
http://github.com/inconvergent/differential-line. 

It is written specifically to be used at the Vilje supercomputer at NTNU HPC. 
Unless you want to use the MPI functionality you should probably use the 
original repo. 

## About

This algorithm is inspired by the way a number of biological things in nature
grows. Among other things it is made to mimic the growth of the human brain, as
well as a great number of plants.

![ani](/img/ani.gif?raw=true "animation")

![img](/img/img.jpg?raw=true "image")

In brief; we start of with a number of connected nodes in a circle. Gradually
we introduce new nodes on the line—prioritizing segments where the curve bends
more sharply.  Over time the curve grows increasingly intricate, but it never
self-intersects.

## Prerequisites

In order for this code to run you must first download and install:

*    `zonemap`: https://github.com/inconvergent/zonemap

You also need

*    `dddUtils`: https://github.com/inconvergent/ddd-utils

The following repo is used to render the resulting vectors in `render_exported.py`

*    `render`: http://github.com/inconvergent/render (Requires `python-cairo`)

## Other Dependencies

The code also depends on:

*    `numpy`
*    `cython`
*    `mpi4py==1.3.1`

## Similar code

If you find this alorithm insteresting you might also want to check out:
https://github.com/inconvergent/differential-mesh.

-----------
http://inconvergent.net
