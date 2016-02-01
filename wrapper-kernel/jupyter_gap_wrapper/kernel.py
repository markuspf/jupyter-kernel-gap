from ipykernel.kernelbase import Kernel
from pexpect import replwrap, EOF, which

from subprocess import check_output
from os import unlink, path

import base64
import imghdr
import re
import signal
import urllib

__version__ = '0.3'

version_pat = re.compile(r'version (\d+(\.\d+)+)')

class GAPKernel(Kernel):
    implementation = 'jupyter_gap_wrapper'
    implementation_version = __version__

    @property
    def language_version(self):
        m = version_pat.search(self.banner)
        return m.group(1)

    _banner = None

    @property
    def banner(self):
        if self._banner is None:
            self._banner = "GAP 4 Jupyter kernel"
        return self._banner

    language_info = {'name': 'gap',
                     'codemirror_mode': 'gap', # note that this does not exist yet
                     'mimetype': 'text/x-gap',
                     'file_extension': '.g'}

    help_links = [ { 'text': "GAP website", 'url': "http://gap-system.org/" },
                   { 'text': "GAP documentation", 'url': "http://gap-system.org/Doc/doc.html" },
                   { 'text': "GAP tutorial", 'url': "http://gap-system.org/Manuals/doc/tut/chap0.html" },
                   { 'text': "GAP reference", 'url': "http://gap-system.org/Manuals/doc/ref/chap0.html" } ]

    def __init__(self, **kwargs):
        Kernel.__init__(self, **kwargs)
        self._start_gap()

    # Horrible, horrible hack
    def _xml_response(self, string):
        return not (re.match("<\?xml", string) is None)

    def _start_gap(self):
        # Signal handlers are inherited by forked processes, and we can't easily
        # reset it from the subprocess. Since kernelapp ignores SIGINT except in
        # message handlers, we need to temporarily reset the SIGINT handler here
        # so that gap and its children are interruptible.
        sig = signal.signal(signal.SIGINT, signal.SIG_DFL)
        try:
            # setup.g contains functions needed for Jupyter interfacing
            setupg = path.dirname(path.abspath(__file__))
            if which( 'gap' ) != None:
                gap_run_command = which( 'gap' )
            elif which( 'gap.sh' ) != None:
                gap_run_command = which( 'gap.sh' )
            else:
                raise NameError( 'gap executable not found')
            self.gapwrapper = replwrap.REPLWrapper( gap_run_command + ' -n -b -T %s/gap/setup.g' % (setupg)
                              , u'gap|| '
                              , None
                              , None
                              , continuation_prompt=u'|| ')
            self.gapwrapper.run_command("\n");
        finally:
            signal.signal(signal.SIGINT, sig)

    def do_execute(self, code, silent, store_history=True,
                   user_expressions=None, allow_stdin=False):
        if not code.strip():
            return {'status': 'ok', 'execution_count': self.execution_count,
                    'payload': [], 'user_expressions': {}}

        interrupted = False
        try:
            output = self.gapwrapper.run_command(code.rstrip().replace('\n', ' ') + " ;", timeout=None)
        except KeyboardInterrupt:
            self.gapwrapper.child.sendintr()
            interrupted = True
            self.gapwrapper._expect_prompt()
            output = self.gapwrapper.child.before
        except EOF:
            output = self.gapwrapper.child.before + 'Restarting GAP'
            self._start_gap()

        if not silent:
            if self._xml_response(output):
                stream_content = { 'source' : 'gap',
                                   'data': { 'image/svg+xml': output },
                                   'metadata': { 'image/svg+xml' : { 'width': 400, 'height': 400 } } }
                self.send_response(self.iopub_socket, 'display_data', stream_content)
                stream_content = {'name': 'stdout', 'text': 'Success'}
                self.send_response(self.iopub_socket, 'stream', stream_content)
            else:
                # Send standard output
                stream_content = {'name': 'stdout', 'text': output}
                self.send_response(self.iopub_socket, 'stream', stream_content)

        if interrupted:
            return {'status': 'abort', 'execution_count': self.execution_count}

        try:
            exitcode = int(self.gapwrapper.run_command('\n').rstrip())
        except Exception:
            exitcode = 1

        if exitcode:
            return {'status': 'error', 'execution_count': self.execution_count,
                    'ename': '', 'evalue': str(exitcode), 'traceback': []}
        else:
            return {'status': 'ok', 'execution_count': self.execution_count,
                    'payload': [], 'user_expressions': {}}

    # This is a rather poor completion at the moment
    def do_complete(self, code, cursor_pos):
        code = code[:cursor_pos]
        default = {'matches': [], 'cursor_start': 0,
                   'cursor_end': cursor_pos, 'metadata': dict(),
                   'status': 'ok'}

        if not code or code[-1] == ' ':
            return default

        tokens = code
        for ch in ";+*-()[]/,.?=:":
            if ch in tokens:
                tokens = tokens.replace(ch, ' ')

        tokens = tokens.split()
        if not tokens:
            return default

        matches = []
        token = tokens[-1]
        start = cursor_pos - len(token)

        # complete bound global variables
        cmd = 'JupyterCompletion("%s");' % token
        output = self.gapwrapper.run_command(cmd).rstrip()
        matches.extend(output.split())

        if not matches:
            return default
        matches = [m for m in matches if m.startswith(token)]

        return {'matches': sorted(matches), 'cursor_start': start,
                'cursor_end': cursor_pos, 'metadata': dict(),
                'status': 'ok'}
