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

# The following are needed to make the help system
# sort of play nice with the wrapper kernel
SetUserPreference("browse", "SelectHelpMatches", false);
SetUserPreference("Pager", "tail");
SetUserPreference("PagerOptions", "");

# Display help in browser not a good option for servers
# SetUserPreference( "HelpViewers", ["browser"])
