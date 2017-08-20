#!/usr/bin/env python

import os
import sys
import json
from distutils.core import setup

from setuptools import setup, find_packages
from setuptools.command.install import install
from distutils.command.install import install as _install

from IPython.utils.tempdir import TemporaryDirectory
from notebook.nbextensions import check_nbextension, install_nbextension, enable_nbextension
from jupyter_client.kernelspec import install_kernel_spec
from jupyter_kernel_gap import __version__


# Kernel spec for GAP
kernel_json = {"argv": [sys.executable,
                        "-m", "jupyter_kernel_gap",
                        "-f", "{connection_file}"],
               "display_name": "GAP 4 (wrapper)",
               "language":     "gap",
               "codemirror_mode": "gap",
               "env": {"PS1": "$"}
}


# Installs the Kernel Spec and NBExtension for Syntax Highlighting
# I am not sure whether this is the correct way of doing it, but
# it works right now
# TODO: Find out whether there is a cleaner way
def install_kernel(c):
    # Write kernel spec in a temporary directory
    user = False
    opt = c.get_cmdline_options()
    if 'install' in opt:
        if 'user' in opt['install']:
            user = True

        c.announce("Installing jupyter kernel spec")
        with TemporaryDirectory() as td:
            with open(os.path.join(td, 'kernel.json'), 'w') as f:
                json.dump(kernel_json, f, sort_keys=True)
            install_kernel_spec(td, kernel_name='gap', user=user)

        c.announce("Installing nbextension for syntax hilighting")
        install_nbextension('jupyter_kernel_gap/resources/gap-mode',
                            overwrite=True, user=user)
        enable_nbextension('notebook', 'gap-mode/main',)


c = setup(name="jupyter-kernel-gap"
           , version=__version__
           , description="A Jupyter kernel for GAP"
           , long_description="A Jupyter kernel for the GAP programming language" +
           " that wraps GAP's REPL"
           , author="Markus Pfeiffer"
           , author_email="markus.pfeiffer@st-andrews.ac.uk"
           , url="https://github.com/gap-packages/jupyter-gap"
           , license="BSD"
           , keywords='jupyter gap computer algebra'
           , packages=["jupyter_kernel_gap"]
           , package_dir={"jupyter_kernel_gap": "jupyter_kernel_gap"}
           , package_data={"jupyter_kernel_gap": ["gap/setup.g",
                                                  "resources/logo-32x32.png",
                                                  "resources/logo-64x64.png"]}
           , classifiers=[
               'Development Status :: 3 - Alpha',
               'Intended Audience :: Science/Research',
               'Topic :: Scientific/Engineering :: Mathematics', 
               'License :: OSI Approved :: BSD License',
               'Programming Language :: Python :: 2',
               'Programming Language :: Python :: 3'
           ]
)

install_kernel(c)
