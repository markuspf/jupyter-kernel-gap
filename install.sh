#!/bin/sh

cd wrapper-kernel
python3 setup.py install
python3 -m jupyter_gap_wrapper.install
cd ..
