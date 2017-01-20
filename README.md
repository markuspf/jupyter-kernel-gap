# jupyter-kernel-gap
Jupyter kernel for GAP 

This `wrapper-kernel` is a Jupyter kernel for the [GAP Computer Algebra System](https://www.gap-system.org/)
based on the same ideas as the [bash wrapper kernel](https://github.com/takluyver/bash_kernel),
to install

```shell
    python setup.py install
```

To use it, use one of the following:

```shell
    jupyter notebook
    jupyter qtconsole --kernel gap
    jupyter console --kernel gap
```

Either the `gap` executable needs to be in your PATH or you have to set the environment
variable `JUPYTER_GAP_EXECUTABLE` to a valid gap executable.

If you want to use the `JUPYTER_DotSplash` function, you will need `graphviz` installed
and in the path. If you want to use `JUPYTER_TikZSplash`, you will need a `TeX` installation
including the `TikZ` packages with `pdflatex` and and `pdf2svg` installed.
