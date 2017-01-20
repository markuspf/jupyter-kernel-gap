from ipykernel.kernelbase import Kernel
from pexpect import replwrap, EOF, which

from subprocess import check_output
from os import unlink, path, getenv

import base64
import imghdr
import re
import signal
import urllib
import json

__version__ = '0.4'
version_pat = re.compile(r'version (\d+(\.\d+)+)')

class GAPKernel(Kernel):
    implementation = 'jupyter_kernel_gap'
    implementation_version = __version__

    _env_executable = 'JUPYTER_GAP_EXECUTABLE'
    _env_options = 'JUPYTER_GAP_OPTIONS'

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

    # At the moment I can only get jupyter notebook to display
    # error messages from the kernel. So be it.
    def _loghack(self, *objs):
        pass
        self.log.error(objs)

    # Is this good enough?
    def _escape_code(self, code):
        return code.replace("\\","\\\\").replace('"','\\"').replace('\n','\\n')

    # Separate out the json response part  from the yucky rest
    # in the near future we should be able to rely on GAP to just
    # respond with json
    def _sep_response(self, string):
        # not the safest way of doing this
        jsonl = string.find('{')
        jsonr = string.rfind('}')

        res_json = string[jsonl:jsonr+1]
        res_rest = string[:jsonl] + string[jsonr+1:]
        return (res_json,res_rest)

    def _start_gap(self):
        # Signal handlers are inherited by forked processes, and we can't easily
        # reset it from the subprocess. Since kernelapp ignores SIGINT except in
        # message handlers, we need to temporarily reset the SIGINT handler here
        # so that gap and its children are interruptible.
        sig = signal.signal(signal.SIGINT, signal.SIG_DFL)
        try:
            # setup.g contains functions needed for Jupyter interfacing
            setupg = path.dirname(path.abspath(__file__))
            gap_run_command = getenv(self._env_executable, "gap")
            gap_extra_options = getenv(self._env_options, "")
            self._loghack("starting GAP: %s" % (gap_run_command))
            self.gapwrapper = replwrap.REPLWrapper(
                                gap_run_command
                                + ' -n -b -T %s %s/gap/setup.g' % (gap_extra_options, setupg)
                              , u'gap|| '
                              , None
                              , None
                              , continuation_prompt=u'|| ')
            self.gapwrapper.run_command("\n");
            # Try to force GAP to not format the output. This doesn't work from
            # setup.g and god alone knows why
            self.gapwrapper.run_command("SetPrintFormattingStatus(\"*stdout*\", false);\n")
        finally:
            signal.signal(signal.SIGINT, sig)

    def do_execute(self, code, silent, store_history=True,
                   user_expressions=None, allow_stdin=False):
        if not code.strip():
            return {'status': 'ok', 'execution_count': self.execution_count,
                    'payload': [], 'user_expressions': {}}

        interrupted = False
        try:
            # We need to get the escaping right :/
            cmd = 'JUPYTER_RunCommand("%s ;");' % (self._escape_code(code))
            self._loghack("command %s" % cmd)
            output = self.gapwrapper.run_command(cmd, timeout=None)
            self._loghack("reply %s" % output)
        except KeyboardInterrupt:
            self.gapwrapper.child.sendintr()
            interrupted = True
            self.gapwrapper._expect_prompt()
            output = self.gapwrapper.child.before
        except EOF:
            output = self.gapwrapper.child.before + 'Restarting GAP'
            self._start_gap()

        if not silent:
            (res_json, res_rest) = self._sep_response(output)
            self._loghack("json part: %s" % (res_json))
            self._loghack("rest part: %s" % (res_rest))
            jsonp = json.loads(res_json)

            if jsonp['status'] == 'ok':
                if 'result' in jsonp:
                    stream_content = jsonp['result']
                    if 'data' in jsonp['result']:
                        self.send_response(self.iopub_socket, 'display_data', stream_content)
                    else:
                        self.send_response(self.iopub_socket, 'stream', stream_content)

                stream_content = {'name': 'stdout', 'text': res_rest}
                self.send_response(self.iopub_socket, 'stream', stream_content)
                return {'status': 'ok', 'execution_count': self.execution_count,
                        'payload': [], 'user_expressions': {}}
            elif jsonp['status'] == 'error':
                stream_content = {'name': 'stderr', 'text': res_rest }
                self.send_response(self.iopub_socket, 'stream', stream_content)
                return {'status': 'error', 'execution_count': self.execution_count,
                        'ename': '', 'evalue': str(-1), 'traceback': []}
            else:
                return {'status': 'error', 'execution_count': self.execution_count,
                        'ename': '', 'evalue': str(-2), 'traceback': []}

        if interrupted:
            return {'status': 'abort', 'execution_count': self.execution_count}


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
        cmd = 'JUPYTER_Completion("%s");' % token
        output = self.gapwrapper.run_command(cmd).rstrip()
        matches.extend(output.split())

        if not matches:
            return default
        matches = [m for m in matches if m.startswith(token)]

        return {'matches': sorted(matches), 'cursor_start': start,
                'cursor_end': cursor_pos, 'metadata': dict(),
                'status': 'ok'}

    def do_inspect(self, code, cursor_pos, detail_level=0):
        return {'status': 'ok', 'found': 'true', 'data': 'Spass hassen spass', 'metadata':''}
