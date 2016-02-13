#  Unbind(PrintPromptHook);

LoadPackage("json");

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

# Get a handle on stdout so we can print to
# it bypassing GAPs formatting.
BindGlobal("JUPYTER_stdout",
           IO_WrapFD(IO_dup(0), 4096, false));
BindGlobal("JUPYTER_print",
function(str)
    IO_Write(JUPYTER_stdout, str);
end);

# Todo: Maybe depend on the json module and use a rec
BindGlobal("JUPYTER_RunCommand",
function(string)
  local stream, result;

  stream := InputTextString(string);
  result := READ_COMMAND_REAL(stream, true);

  if result[1] = true then
    if Length(result) = 1 then
        JUPYTER_print("{ \"status\": \"ok\" }");
    elif Length(result) = 2 then
        if IsRecord(result[2]) and IsBound(result[2].json) then
            JUPYTER_print( GapToJsonString( rec(
                                status := "ok",
                                result := result[2]
                               ) ) );
        else
            JUPYTER_print( GapToJsonString( rec(
                                status := "ok",
                                result := rec( name := "stdout"
                                             , text := ViewString(result[2]))
                               ) ) );
        fi;
    else
        Print("{ \"status\": \"error\" }");
    fi;
  else
    Print("{ \"status\": \"error\" }");
  fi;
end);

# This is a rather basic helper function to do
# completion. It is related to the completion
# function provided in lib/cmdledit.g in the GAP
# distribution
BindGlobal("JUPYTER_Completion",
function(tok)
  local cand, i;

  cand := IDENTS_BOUND_GVARS();

  for i in cand do
    if PositionSublist(i, tok) = 1 then
      Print(i, "\n");
    fi;
  od;
end);

# This is still an ugly hack, but its already much better than before!
BindGlobal("JUPYTER_DotSplash",
function(dot)
    local fn, fd, r;


    fn := TmpName();
    fd := IO_File(fn, "w");
    IO_Write(fd, dot);
    IO_Close(fd);

    fd := IO_Popen(IO_FindExecutable("dot"), ["-Tsvg", fn], "r");
    r := IO_ReadUntilEOF(fd);
    IO_close(fd);
    IO_unlink(fn);

    return rec( json := true
              , source := "gap"
              , data := rec( ("image/svg+xml") := r )
              , metadata := rec( ("image/svg+xml") := rec( width := 500, height := 500 ) ) );
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
             Print("<a target=\"_blank\" href=\"", p, "\">Help</a>\n");
         end
        );

MakeReadWriteGlobal("HELP_SHOW_MATCHES");
UnbindGlobal("HELP_SHOW_MATCHES");
DeclareGlobalFunction("HELP_SHOW_MATCHES");
InstallGlobalFunction(HELP_SHOW_MATCHES, function( books, topic, frombegin )
local   exact,  match,  x,  lines,  cnt,  i,  str,  n;

  # first get lists of exact and other matches
  x := HELP_GET_MATCHES( books, topic, frombegin );
  exact := x[1];
  match := x[2];

  # no topic found
  if 0 = Length(match) and 0 = Length(exact)  then
    Print( "Help: no matching entry found\n" );
    return false;

  # one exact or together one topic found
  elif 1 = Length(exact) or (0 = Length(exact) and 1 = Length(match)) then
    if Length(exact) = 0 then exact := match; fi;
    i := exact[1];
    str := Concatenation("Help: Showing `", i[1].bookname,": ",
                                               StripEscapeSequences(i[1].entries[i[2]][1]), "'\n");
    # to avoid line breaking when str contains escape sequences:
    n := 0;
    while n < Length(str) do
      Print(str{[n+1..Minimum(Length(str),
                                    n + QuoInt(SizeScreen()[1] ,2))]}, "\c");
      n := n + QuoInt(SizeScreen()[1] ,2);
    od;
    HELP_PRINT_MATCH(i);
    return true;

  # more than one topic found, show overview in pager
  else
    lines :=
        ["","Help: several entries match this topic - type ?2 to get match [2]\n"];
        # there is an empty line in the beginning since `tail' will start from line 2
    HELP_LAST.TOPICS:=[];
    cnt := 0;
    # show exact matches first
    match := Concatenation(exact, match);
    for i  in match  do
      cnt := cnt+1;
      topic := Concatenation(i[1].bookname,": ",i[1].entries[i[2]][1]);
      Add(HELP_LAST.TOPICS, i);
      Add(lines,Concatenation("[",String(cnt),"] ",topic));
    od;
    Pager(rec(lines := lines, formatted := true, start := 2 ));
    return true;
  fi;
end);

# Make sure that we don't insert ugly line breaks into the
# output stream
SetUserPreference("browse", "SelectHelpMatches", false);
SetUserPreference("Pager", "tail");
SetUserPreference("PagerOptions", "");
# This is of course complete nonsense if you're running the jupyter notebook
# on your local machine.
SetHelpViewer("jupyter_online");
