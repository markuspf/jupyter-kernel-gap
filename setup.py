#!/usr/bin/env python

import os
import sys
import json
from distutils.core import setup
from IPython.utils.tempdir import NamedFileInTemporaryDirectory
from jupyter_gap_wrapper import __version__


# Kernel spec for GAP
kernel_json = {"argv":[sys.executable,"-m","jupyter_gap_wrapper", "-f", "{connection_file}"],
 "display_name":"GAP",
 "language":"gap",
 "codemirror_mode":"gap", # note that this does not exist yet
 "env":{"PS1": "$"}
}

# Write kernel spec in a temporary directory
kernel_json_tempfile = NamedFileInTemporaryDirectory('kernel.json', 'w')
kernel_json_file = kernel_json_tempfile.file
with kernel_json_file:
    json.dump(kernel_json, kernel_json_file, sort_keys=True)

kernelpath = os.path.join("share", "jupyter", "kernels", "gap")
kernelfiles = [kernel_json_file.name,
        "jupyter_gap_wrapper/resources/logo-32x32.png",
        "jupyter_gap_wrapper/resources/logo-64x64.png"]


setup( name="jupyter_gap_wrapper"
     , version=__version__
     , description="A Jupyter wrapper kernel for GAP"
     , author="Markus Pfeiffer"
     , url="https://github.com/gap-system/jupyter-gap"
     , packages=["jupyter_gap_wrapper"]
     , package_dir={"jupyter_gap_wrapper": "jupyter_gap_wrapper"}
     , package_data={"jupyter_gap_wrapper": ["gap/setup.g","resources/logo-32x32.png","resources/logo-64x64.png"]}
     , data_files=[(kernelpath, kernelfiles)]
     )
