# jupyter-gap
Jupyter kernels for GAP 

Please note that this software is still in the early stages of development and names of kernels, assumptions,
and architecture might change on a day-to-day basis without notice.

## wrapper-kernel

The `wrapper-kernel' is a Jupyter kernel based on the [bash wrapper kernel](https://github.com/takluyver/bash_kernel),
to install

```shell
    pip install gap_kernel
    python -m gap_kernel.install
```

To use it, use one of the following:

```shell
    ipython notebook
    ipython qtconsole --kernel gap
    ipython console --kernel gap
```

