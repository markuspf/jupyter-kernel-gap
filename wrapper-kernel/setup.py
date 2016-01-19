#!/usr/bin/env python

import sys
from distutils.core import setup

setup( name="jupyter_gap_wrapper"
     , version="0.3"
     , description="A Jupyter wrapper kernel for GAP"
     , author="Markus Pfeiffer"
     , url="https://github.com/gap-system/jupyter-gap"
     , packages=["jupyter_gap_wrapper"]
     , package_dir={"jupyter_gap_wrapper": "jupyter_gap_wrapper"}
     , package_data={"jupyter_gap_wrapper": ["gap/setup.g","resources/logo-32x32.png","resources/logo-64x64.png"]}
     ,
     )
