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

# The following are needed to make the help system
# sort of play nice with the wrapper kernel
SetUserPreference("browse", "SelectHelpMatches", false);
SetUserPreference("Pager", "cat");
SetUserPreference("PagerOptions", "");


