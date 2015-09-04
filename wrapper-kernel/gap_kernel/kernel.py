from IPython.kernel.zmq.kernelbase import Kernel
from pexpect import replwrap, EOF

from subprocess import check_output
from os import unlink

import base64
import imghdr
import re
import signal
import urllib

__version__ = '0.1'


change_prompt_cmd_lb = """
  Unbind(PrintPromptHook);
  PrintPromptHook := function()
    local cp;
    cp := CPROMPT();
    if cp = "gap> " then
      cp := "gap# ";
    fi;
    if Length(cp)>0 and cp[1] = 'b' then
      cp := "brk#";
    fi;
    if Length(cp)>0 and cp[1] = '>' then
      cp := "#";
    fi;
    PRINT_CPROMPT(cp);
  end;
"""

change_prompt_cmd = 'PrintPromptHook := function() local cp; cp := CPROMPT(); if cp = "gap> " then cp := "gap# "; fi; if Length(cp) > 0 and cp[1] = \'>\' then cp := "+"; fi; PRINT_CPROMPT(cp); end;\n'

version_pat = re.compile(r'version (\d+(\.\d+)+)')

from .images import (
    extract_image_filenames, display_data_for_image, image_setup_cmd
)


class GAPKernel(Kernel):
    implementation = 'gap_kernel'
    implementation_version = __version__

    @property
    def language_version(self):
        m = version_pat.search(self.banner)
        return m.group(1)

    _banner = None

    @property
    def banner(self):
        if self._banner is None:
            self._banner = "GAP kernel"
        return self._banner

    language_info = {'name': 'gap',
                     'codemirror_mode': 'shell',
                     'mimetype': 'text/x-sh',
                     'file_extension': '.g'}

    def __init__(self, **kwargs):
        Kernel.__init__(self, **kwargs)
        self._start_gap()

    def _start_gap(self):
        # Signal handlers are inherited by forked processes, and we can't easily
        # reset it from the subprocess. Since kernelapp ignores SIGINT except in
        # message handlers, we need to temporarily reset the SIGINT handler here
        # so that bash and its children are interruptible.
        sig = signal.signal(signal.SIGINT, signal.SIG_DFL)
        try:
            self.gapwrapper = replwrap.REPLWrapper('gap.sh -b', u'gap> ',
                              change_prompt_cmd,
                              new_prompt=u'gap#',
                              continuation_prompt=u'+')
        #    self.gapwrapper.run_command("\n\n");
        finally:
            signal.signal(signal.SIGINT, sig)

        # Register Bash function to write image data to temporary file
        #self.gapwrapper.run_command(image_setup_cmd)

    def do_execute(self, code, silent, store_history=True,
                   user_expressions=None, allow_stdin=False):
        if not code.strip():
            return {'status': 'ok', 'execution_count': self.execution_count,
                    'payload': [], 'user_expressions': {}}

        interrupted = False
        try:
            print("running command: %s" % (code.rstrip()))
            output = self.gapwrapper.run_command(code.rstrip(), timeout=None)
            print("got output %s" % output)
        except KeyboardInterrupt:
            self.gapwrapper.child.sendintr()
            interrupted = True
            self.gapwrapper._expect_prompt()
            output = self.gapwrapper.child.before
        except EOF:
            output = self.gapwrapper.child.before + 'Restarting GAP'
            self._start_gap()

        if not silent:
            image_filenames, output = extract_image_filenames(output)

            # Send standard output
            stream_content = {'name': 'stdout', 'text': output}
            self.send_response(self.iopub_socket, 'stream', stream_content)

            # Send images, if any
            for filename in image_filenames:
                try:
                    data = display_data_for_image(filename)
                except ValueError as e:
                    message = {'name': 'stdout', 'text': str(e)}
                    self.send_response(self.iopub_socket, 'stream', message)
                else:
                    self.send_response(self.iopub_socket, 'display_data', data)

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

    def do_complete(self, code, cursor_pos):
        code = code[:cursor_pos]
        default = {'matches': [], 'cursor_start': 0,
                   'cursor_end': cursor_pos, 'metadata': dict(),
                   'status': 'ok'}

        if not code or code[-1] == ' ':
            return default

        tokens = code.replace(';', ' ').split()
        if not tokens:
            return default

        matches = []
        token = tokens[-1]
        start = cursor_pos - len(token)

        if token[0] == '$':
            # complete variables
            cmd = 'compgen -A arrayvar -A export -A variable %s' % token[1:] # strip leading $
            output = self.bashwrapper.run_command(cmd).rstrip()
            completions = set(output.split())
            # append matches including leading $
            matches.extend(['$'+c for c in completions])
        else:
            # complete functions and builtins
            cmd = 'compgen -cdfa %s' % token
            output = self.bashwrapper.run_command(cmd).rstrip()
            matches.extend(output.split())
            
        if not matches:
            return default
        matches = [m for m in matches if m.startswith(token)]

        return {'matches': sorted(matches), 'cursor_start': start,
                'cursor_end': cursor_pos, 'metadata': dict(),
                'status': 'ok'}


