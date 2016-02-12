#  Unbind(PrintPromptHook);

# Set the prompt to something that pexpect can
# handle
BindGlobal("PrintPromptHook",
function()
    local cp;
    cp := CPROMPT();
    if cp = "gap> " then
      cp := "gap|| ";
    fi;
    if Length(cp)>0 and cp[1] = 'b' then
      cp := "brk|| ";
    fi;
    if Length(cp)>0 and cp[1] = '>' then
      cp := "||";
    fi;
    PRINT_CPROMPT(cp);
end);

# This is a rather basic helper function to do
# completion. It is related to the completion
# function provided in lib/cmdledit.g in the GAP
# distribution
BindGlobal("JupyterCompletion",
function(tok)
  local cand, i;

  cand := IDENTS_BOUND_GVARS();

  for i in cand do
    if PositionSublist(i, tok) = 1 then
      Print(i, "\n");
    fi;
  od;
end);

# This is a really ugly hack, but at the moment
# it works nicely enough to demo stuff.
# In the future we might want to dump the dot
# into a temporary file and then exec dot on it.
BindGlobal("JupyterDotSplash",
function(dot)
    local fn, fd;

    fn := TmpName();
    fd := IO_File(fn, "w");
    IO_Write(fd, dot);
    IO_Close(fd);

    Exec("dot","-Tsvg",fn);

    IO_unlink(fn);
end);

# This is another ugly hack to make the GAP Help System
# play ball. Let us please fix this soon.
HELP_VIEWER_INFO.jupyter_online :=
    rec(
         type := "url",
         show := function(url)
             local p,r;

             p := url;

             for r in GAPInfo.RootPaths do
                 p := ReplacedString(url, r, "https://cloud.gap-system.org/");
             od;
             Print("<doclink dst=\"", p, "\">\n");
         end
        );

# Make sure that we don't insert ugly line breaks into the
# output stream
SetPrintFormattingStatus("*stdout*", false);

# The following are needed to make the help system
# sort of play nice with the wrapper kernel
SetUserPreference("browse", "SelectHelpMatches", false);
SetUserPreference("Pager", "tail");
SetUserPreference("PagerOptions", "");
# This is of course complete nonsense if you're running the jupyter notebook
# on your local machine.
SetHelpViewer("jupyter-online");
