A simple IPython kernel for GAP

This requires IPython 3.

To use it, run one of:

.. code:: shell

    ipython notebook
    # In the notebook interface, select Bash from the 'New' menu
    ipython qtconsole --kernel gap
    ipython console --kernel gap

For details of how this works, see the Jupyter docs on `wrapper kernels
<http://jupyter-client.readthedocs.org/en/latest/wrapperkernels.html>`_, and
Pexpect's docs on the `replwrap module
<http://pexpect.readthedocs.org/en/latest/api/replwrap.html>`_

Note that the code assumes that gap.sh is in the path.
