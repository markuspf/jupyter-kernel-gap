It seems like we can do a native implementation in HPCGAP and an implementation involving a Python proxy process for
GAP4. It might also be possible to do a proxy-free implementation in GAP4 by spawning a purely C thread inside the kernel
to handle heartbeat.

Notes from Min Ragan-Kelley's Q&A session on the Jupyter kernel:

Rich REPL protocol (returns complex info including 'msg_type' and 'content' which may be processed dependently on their type), based on ZeroMQ + JSON. More than one client may be connected to the same kernel at a time.

Kernel is any application compliant with the protocol. May be wrapper around another application.

https://github.com/ipython/ipython/wiki/IPython-kernels-for-other-languages (see also links in the bottom of this page)

Heartbeat messages - will be deprecated. Needed only for the client which is not the one which started the kernel. See ipython/ipykernel/heartbeat.py - it uses Python threads for heartbeats:

https://github.com/ipython/ipykernel/blob/c5162fb79ea1929f2fd9b47d081485d557779822/ipykernel/heartbeat.py

Syntax highlighting - http://codemirror.net/. One could create a mode for GAP and submit a pull request. 

Autocompletion will be provided by the kernel.

To be implemented:
kernel_info_request
kernel_info_reply
version
mimetype
file_extension
etc.

See also 
* http://jupyter-client.readthedocs.org/en/latest/messaging.html
* http://jupyter-client.readthedocs.org/en/stable/wrapperkernels.html

MOST COMMON MISTAKE: wrong socket type! May work for a while and then misbehave when a new connection is started. Useful flag for debugging ZeroMQ is "mandatory". 
