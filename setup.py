#!/usr/bin/env python

from setuptools import setup
from setuptools.command.install import install as _install

from jupyter_kernel_gap import __version__

class install(_install):
    r"""
    Custom install command for the gap jupyter kernel
    """
    def run(self):
        import os
        import sys
        import json
        from IPython.utils.tempdir import TemporaryDirectory
        from notebook.nbextensions import check_nbextension, install_nbextension, enable_nbextension
        from jupyter_client.kernelspec import install_kernel_spec

        # run from distutils install
        _install.run(self)

        # install kernel spec
        self.announce("Installing jupyter kernel spec")
        kernel_json = {"argv": [sys.executable,
                                "-m", "jupyter_kernel_gap",
                                "-f", "{connection_file}"],
                       "display_name": "GAP 4 (wrapper)",
                       "language":     "gap",
                       "codemirror_mode": "gap",
                       "env": {"PS1": "$"}
        }
        with TemporaryDirectory() as td:
            with open(os.path.join(td, 'kernel.json'), 'w') as f:
                json.dump(kernel_json, f, sort_keys=True)
            install_kernel_spec(td, kernel_name='gap-wrapper', user=self.user)

        # kernel installation
        self.announce("Installing nbextension for syntax hilighting")
        install_nbextension('jupyter_kernel_gap/resources/gap-mode',
                            overwrite=True, user=self.user)
        enable_nbextension('notebook', 'gap-mode/main',)


setup(name="jupyter-kernel-gap",
           version=__version__,
           description="A Jupyter kernel for GAP",
           long_description=("A Jupyter kernel for the GAP programming language"
                             " that wraps GAP's REPL"),
           author="Markus Pfeiffer",
           author_email="markus.pfeiffer@st-andrews.ac.uk",
           url="https://github.com/gap-packages/jupyter-kernel-gap",
           license="BSD",
           keywords='jupyter gap computer algebra',
           packages=["jupyter_kernel_gap"],
           package_data={"jupyter_kernel_gap": ["gap/setup.g",
                                                 "resources/*",
                                                  "resources/gap-mode/*"]},
           install_requires=['jupyter'],
           classifiers=[
               'Development Status :: 3 - Alpha',
               'Intended Audience :: Science/Research',
               'Topic :: Scientific/Engineering :: Mathematics', 
               'License :: OSI Approved :: BSD License',
               'Programming Language :: Python :: 2',
               'Programming Language :: Python :: 3',
               ],
            cmdclass=dict(install=install)
)
