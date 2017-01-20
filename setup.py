#!/usr/bin/env python

import os
import sys
import json
from distutils.core import setup
from IPython.utils.tempdir import NamedFileInTemporaryDirectory
from jupyter_kernel_gap import __version__


# Kernel spec for GAP
kernel_json = {"argv":[sys.executable,"-m","jupyter_kernel_gap", "-f", "{connection_file}"],
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
        "jupyter_kernel_gap/resources/logo-32x32.png",
        "jupyter_kernel_gap/resources/logo-64x64.png"]


setup( name="jupyter-kernel-gap"
     , version=__version__
     , description="A Jupyter kernel for GAP"
     , long_description="A Jupyter kernel for the GAP programming language that wraps GAP's REPL"
     , author="Markus Pfeiffer"
     , author_email="markus.pfeiffer@st-andrews.ac.uk"
     , url="https://github.com/gap-packages/jupyter-gap"
     , license="BSD"
     , keywords='jupyter gap computer algebra'
     , packages=["jupyter_kernel_gap"]
     , package_dir={"jupyter_kernel_gap": "jupyter_kernel_gap"}
     , package_data={"jupyter_kernel_gap": ["gap/setup.g","resources/logo-32x32.png","resources/logo-64x64.png"]}
     , data_files=[(kernelpath, kernelfiles)]
     , classifiers=[
         'Development Status :: 3 - Alpha',
         'Intended Audience :: Science/Research',
         'Topic :: Scientific/Engineering :: Mathematics', 
         'License :: OSI Approved :: BSD License',
         'Programming Language :: Python :: 2',
         'Programming Language :: Python :: 3',
     ]
     )
