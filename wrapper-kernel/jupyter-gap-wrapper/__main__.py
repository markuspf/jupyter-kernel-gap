from IPython.kernel.zmq.kernelapp import IPKernelApp
from .kernel import GAPKernel
IPKernelApp.launch_instance(kernel_class=GAPKernel)
