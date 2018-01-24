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

from . import __version__

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

    help_links = [ { 'text': "GAP website", 'url': "https://www.gap-system.org/" },
                   { 'text': "GAP documentation", 'url': "https://www.gap-system.org/Doc/doc.html" },
                   { 'text': "GAP tutorial", 'url': "htts://www.gap-system.org/Manuals/doc/tut/chap0.html" },
                   { 'text': "GAP reference", 'url': "https://www.gap-system.org/Manuals/doc/ref/chap0.html" } ]

    def __init__(self, **kwargs):
        Kernel.__init__(self, **kwargs)
        self._start_gap()

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

        # This can now contain more than one json dict.
        # I will punt fixing this until after I move to
        # direct ZMQ or libgap
        res_json = string[jsonl:jsonr+1].split("}{")
        if len(res_json) > 1:
            res_json[0] = res_json[0] + '}'
            for i in range(1,len(res_json)-1):
                res_json[i] = '{' + res_json[i] + '}'
            res_json[-1] = '{' + res_json[-1]
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
            self.log.info("starting GAP: %s" % (gap_run_command))
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
            self.log.debug("executing command: %s" % cmd)
            output = self.gapwrapper.run_command(cmd, timeout=None)
            self.log.debug("reply: %s" % output)
        except KeyboardInterrupt:
            self.gapwrapper.child.sendintr()
            interrupted = True
            self.gapwrapper._expect_prompt()
            output = self.gapwrapper.child.before
        except EOF:
            output = self.gapwrapper.child.before + 'Restarting GAP'
            self._start_gap()

        if not silent:
            (res_jsons, res_rest) = self._sep_response(output)
            self.log.debug("json part: %s" % (res_jsons))
            self.log.debug("rest part: %s" % (res_rest))

            err = False
            for res_json in res_jsons:
                self.log.debug("current json: %s" % (res_json))
                jsonp = json.loads(res_json, strict=False)
                self.log.debug("parsed json: %s" % (jsonp))
                if jsonp['status'] == 'ok':
                    if 'result' in jsonp:
                        stream_content = jsonp['result']
                        if 'data' in jsonp['result']:
                            self.send_response(self.iopub_socket, 'display_data', stream_content)
                        else:
                            self.send_response(self.iopub_socket, 'stream', stream_content)
                elif jsonp['status'] == 'error':
                    err = True
                    # We do not have specific error messages for each result yet,
                    # so we can only burst the error out wholesale. (and the error message is
                    # just what we have scraped)
                    # stream_content = {'name': 'stderr', 'text': res_rest }
                    # self.send_response(self.iopub_socket, 'stream', stream_content)
                else:
                    err = True

            if len(res_rest.strip()) > 0:
                stream_content = {'name': 'stderr', 'text': res_rest}
                self.send_response(self.iopub_socket, 'stream', stream_content)

            if err:
                return {'status': 'error', 'execution_count': self.execution_count,
                        'ename': '', 'evalue': str(-2), 'traceback': []}
            else:
                return {'status': 'ok', 'execution_count': self.execution_count,
                        'payload': [], 'user_expressions': {}}

        if interrupted:
            return {'status': 'abort', 'execution_count': self.execution_count}


    # This is a rather poor completion at the moment
    def do_complete(self, code, cursor_pos):
        self.log.debug("completing %s %s" % (code, cursor_pos))
        # complete bound global variables
        cmd = 'JUPYTER_print(JUPYTER_Complete("%s", %s));' % (self._escape_code(code), cursor_pos)
        output = self.gapwrapper.run_command(cmd).rstrip()
        self.log.debug("output %s" % (output,))
        (res_jsons, res_rest) = self._sep_response(output)
        jsonp = json.loads(res_jsons[0], strict=False)
        self.log.debug("parsed json %s" % (jsonp,))
        return jsonp

    def do_inspect(self, code, cursor_pos, detail_level=0):
        self.log.debug("inspecting %s %s" % (code, cursor_pos))
        cmd = 'JUPYTER_print(JUPYTER_Inspect("%s", %s));' % (self._escape_code(code), cursor_pos)
        output = self.gapwrapper.run_command(cmd).rstrip()
        (res_jsons, res_rest) = self._sep_response(output)
        self.log.debug("json part: %s" % (res_jsons))
        self.log.debug("rest part: %s" % (res_rest))
        self.log.debug("current json: %s" % (res_jsons[0]))
        jsonp = json.loads(res_jsons[0], strict=False)
        self.log.debug("parsed json: %s" % (jsonp,))
        return jsonp
