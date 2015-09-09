#!/usr/bin/env python

import sys
from distutils.core import setup

setup( name="jupyter-gap-wrapper"
     , version="0.3"
     , description="A Jupyter wrapper kernel for GAP"
     , author="Markus Pfeiffer"
     , url="https://github.com/gap-system/jupyter-gap"
     , packages=["jupyter-gap-wrapper"]
     , package_dir={"jupyter-gap-wrapper": "jupyter-gap-wrapper"}
     , package_data={"jupyter-gap-wrapper": ["gap/setup.g"]}
     ,
     )
