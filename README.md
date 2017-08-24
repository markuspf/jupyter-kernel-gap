# jupyter-kernel-gap

A Jupyter kernel for the [GAP Computer Algebra System](https://www.gap-system.org/).

## Installation

You need a very recent version (current `master` or wait for GAP 4.9)
of [GAP](https://www.gap-system.org) installed, and either `gap` has to be in
your `PATH` or you have to set the environment variable `JUPYTER_GAP_EXECUTABLE`
to your gap executable.

To install the kernel

```shell
    python setup.py install
```

or if you want to install the latest released version

```
    pip install jupyter-kernel-gap
```

should work, too.

## Getting Started

To use `jupyter-kernel-gap`, use one of the following:

```shell
    jupyter notebook
    jupyter qtconsole --kernel gap
    jupyter console --kernel gap
```

If you want to use the `JUPYTER_DotSplash` function, you will need `graphviz` installed
and in the path. If you want to use `JUPYTER_TikZSplash`, you will need a `TeX` installation
including the `TikZ` packages with `pdflatex` and and `pdf2svg` installed.

## Bug reports and feature requests

Please submit bug reports and feature requests via our GitHub issue tracker:

  <https://github.com/gap-packages/jupyter-kernel-gap/issues>


# License

jupyter-kernel-gap is free software; you can redistribute it and/or modify it
under the terms of the BSD 3-clause license.

For details see the file LICENSE.
