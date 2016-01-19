import json
import os
import sys

from jupyter_client.kernelspec import install_kernel_spec
from IPython.utils.tempdir import TemporaryDirectory

from os.path import dirname,abspath

from shutil import copy as file_copy

kernel_json = {"argv":[sys.executable,"-m","jupyter_gap_wrapper", "-f", "{connection_file}"],
 "display_name":"GAP",
 "language":"gap",
 "codemirror_mode":"gap", # note that this does not exist yet
 "env":{"PS1": "$"}
}

def install_my_kernel_spec(user=True):
    with TemporaryDirectory() as td:
        os.chmod(td, 0o755) # Starts off as 700, not user readable
        with open(os.path.join(td, 'kernel.json'), 'w') as f:
            json.dump(kernel_json, f, sort_keys=True)
        # TODO: Copy resources once they're specified
        path_of_file = dirname( abspath(__file__) ) + "/resources/"
        file_copy(path_of_file + "logo-32x32.png", td )
        file_copy(path_of_file + "logo-64x64.png", td )
        print('Installing Jupyter kernel spec from')
        install_kernel_spec(td, 'gap', user=user, replace=True)

def main(argv=None):
    install_my_kernel_spec()

if __name__ == '__main__':
    main()
