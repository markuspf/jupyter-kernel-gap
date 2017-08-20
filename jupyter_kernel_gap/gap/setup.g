# This is so that the help comes
# out formatted suitably for the
# help bubbles until we make
# separate formatting functions
# for Jupyter (no really)
SizeScreen([55,25]);

#  Unbind(PrintPromptHook);
last := "2b defined";
last2 := "2b defined";

# Compatibility hacks for versions < 4.9.0
if ViewString(true) = "<object>" then
    InstallMethod(ViewString, "for a boolean", true, [IsBool], 5, String);
fi;

if ViewString(rec()) = "<object>" then
    InstallMethod(ViewString, "for a record", true, [IsRecord], 5, String);
fi;

if ViewString(FamilyObj(1)) = "<object>" then
    InstallMethod(ViewString, "for a family", true, [IsFamily], 5,
    function( family )
        return Concatenation("<Family: \"", family!.NAME, "\">");
    end);

    InstallMethod(DisplayString, "for a family", true, [IsFamily], 5,
    function ( family )
        local  res, req_flags, imp_flags, fnams;

        res := "";
        Append(res, STRINGIFY("name:\n    ", family!.NAME));
        req_flags := TRUES_FLAGS(family!.REQ_FLAGS);
        fnams := NamesFilter(req_flags);
        fnams := JoinStringsWithSeparator(fnams, "\n    ");
        Append(res, STRINGIFY("\nrequired filters:\n    ", fnams));
        imp_flags := family!.IMP_FLAGS;
        if imp_flags <> [  ]  then
            fnams := NamesFilter(TRUES_FLAGS(imp_flags));
            fnams := JoinStringsWithSeparator(fnams, "\n    ");
            Append(res, STRINGIFY( "\nimplied filters:\n    ", fnams));
        fi;
        return res;
    end);
fi;

if ViewString(TypeObj(1)) = "<object>" then
    InstallMethod(ViewString, "for a type", true, [IsType], 5,
    function(type)
        local family, flags, res, i;

        family := type![1];
        flags := NamesFilter(type![2]);

        res := "<Type: (";
        Append(res, family!.NAME);
        Append(res, ", [");

        if Length(flags) > 0 then
            Append(res, STRINGIFY(flags[1]));
            for i in [2..Minimum(3,Length(flags))] do
                Append(res, STRINGIFY(",", flags[i]));
            od;
            if Length(flags) > 3 then
                Append(res, ",...");
            fi;
        else
            Append(res, " ");
        fi;
        Append(res, "])>");
        return res;
    end);

    InstallMethod(DisplayString, "for a type", true, [IsType], 5,
    function(type)
        local  res, family, flags, data, fnams;

        res := "";
        family := type![1];
        flags := type![2];
        data := type![POS_DATA_TYPE];

        Append(res, STRINGIFY("family:\n    ", family!.NAME));
        if flags <> [  ] or data <> false  then
            fnams := NamesFilter(TRUES_FLAGS(flags));
            fnams := JoinStringsWithSeparator(fnams, "\n    ");
            Append(res, STRINGIFY("\nfilters:\n    ", fnams));
            if data <> false  then
                Append(res, STRINGIFY("\ndata:\n", data ) );
            fi;
        fi;
        return res;
    end);
fi;

if ViewString(Size) = "<object>" then
InstallMethod( ViewString, "for an operation", true, [IsOperation], 0,
function ( op )
    local class,  flags,  types,  catok,  repok,  propok,  seenprop,
          t;
    class := "Operation";
    if IS_IDENTICAL_OBJ(op,IS_OBJECT) then
        class := "Filter";
    elif op in CONSTRUCTORS then
        class := "Constructor";
    elif IsFilter(op) then
        class := "Filter";
        flags := TRUES_FLAGS(FLAGS_FILTER(op));
        types := INFO_FILTERS{flags};
        catok := true;
        repok := true;
        propok := true;
        seenprop := false;
        for t in types do
            if not t in FNUM_REPS then
                repok := false;
            fi;
            if not t in FNUM_CATS then
                catok := false;
            fi;
            if not t in FNUM_PROS and not t in FNUM_TPRS then
                propok := false;
            fi;
            if t in FNUM_PROS then
                seenprop := true;
            fi;
        od;
        if seenprop and propok then
            class := "Property";
        elif catok then
            class := "Category";
        elif repok then
            class := "Representation";
        fi;
    elif Tester(op) <> false  then
        # op is an attribute
        class := "Attribute";
    fi;
    return STRINGIFY("<", class, " \"",
                     NAME_FUNC(op), "\">");
end);
fi;

BindGlobal("DisplayCategoriesOfObject",
function(obj)
    Print(JoinStringsWithSeparator(CategoriesOfObject(obj), "\n"));
end);

BindGlobal("LoadInspectionData",
function()
    local tree;
end);


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
           OutputTextFile("*stdout*", true));
DeclareOperation("ToJsonStream", [IsOutputTextStream, IsObject]);

InstallMethod(ToJsonStream, "for a record",
[IsOutputTextStream, IsRecord],
function(os, r)
    local i, k, l, AppendComponent;
    AppendComponent := function(k, v)
        WriteAll(os, STRINGIFY("\"", k, "\" : "));
        ToJsonStream(os, v);
    end;

    WriteAll(os, "{");
    k := NamesOfComponents(r);
    for i in [1..Length(k)-1] do
        AppendComponent(k[i], r.(k[i]));
        WriteAll(os, ",");
    od;
    if Length(k) > 0 then
        AppendComponent(k[Length(k)], r.(k[Length(k)]));
    fi;
    WriteAll(os, "}");
end);

InstallMethod(ToJsonStream, "for a string",
[IsOutputTextStream, IsString],
function(os, s)
    local ch, byte;

    WriteByte(os, INT_CHAR('"'));
    for ch in s do
        byte := INT_CHAR(ch);
        if byte > 3 then
            if byte in [ 92, 34 ] then
                WriteByte(os, 92);
                WriteByte(os, byte);
            elif byte = 10 then # \n
                WriteByte(os, 92);
                WriteByte(os, 110); # n
            elif byte = 13 then
                WriteByte(os, 92); # \r
                WriteByte(os, 114); # r
            else;
                WriteByte(os, byte);
            fi;
        fi;
    od;
    WriteByte(os, INT_CHAR('"'));
end);

InstallMethod(ToJsonStream, "for a list",
[IsOutputTextStream, IsList],
function(os, l)
    local i;
    AppendTo(os, "[");
    if Length(l) > 0 then
        for i in [1..Length(l)-1] do
            ToJsonStream(os, l[i]);
            AppendTo(os, ",");
        od;
        ToJsonStream(os, l[Length(l)]);
    fi;
    AppendTo(os, "]");
end);

InstallMethod(ToJsonStream, "for an integer",
[IsOutputTextStream, IsInt],
function(os, i)
   AppendTo(os, String(i));
end);

InstallMethod(ToJsonStream, "for a bool",
[IsOutputTextStream, IsBool],
function(os, b)
   WriteAll(os, ViewString(b));
end);

BindGlobal("JUPYTER_print",
function(obj)
    ToJsonStream(JUPYTER_stdout, obj);
end);

BindGlobal("JUPYTER_RunCommand",
function(string)
  local stream, result, r;

  stream := InputTextString(string);
  result := READ_ALL_COMMANDS(stream, true);

  for r in result do
      if r[1] = true then # statement executed successfully
          if Length(r) = 1 then    # no return value
              JUPYTER_print( rec( status := "ok" ) );
          elif Length(r) = 2 then  # print return value
              last2 := last;
              last := r[2];

              if IsRecord(r[2]) and IsBound(r[2].json) then
                  JUPYTER_print( rec(
                                      status := "ok",
                                      result := r[2]
                                     ) );
              else
                  JUPYTER_print( rec(
                                      status := "ok",
                                      result := rec( name := "stdout"
                                                   , text := Concatenation(ViewString(r[2]), "\n"))
                                     ) );
              fi;
          else # this should really not happen
              JUPYTER_print( rec( status := "error") );
          fi;
      else # Error
          JUPYTER_print( rec( status := "error") );
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

BindGlobal("JUPYTER_SubgroupLatticeSplash",
function(group)
    local fn, fd, r, L, dot;

    fn := TmpName();

    L := LatticeSubgroups(group);
    DotFileLatticeSubgroups(L, fn);

    fd := IO_Popen(IO_FindExecutable("dot"), ["-Tsvg", fn], "r");
    r := IO_ReadUntilEOF(fd);
    IO_close(fd);
    IO_unlink(fn);

    return rec( json := true
              , source := "gap"
              , data := rec( ("image/svg+xml") := r)
              , metadata := rec( ("image/svg+xml") := rec( width := 500, height := 500 ) ) );
end);


# To show TikZ in a GAP jupyter notebook
BindGlobal("JUPYTER_TikZSplash",
function(tikz)
  local tmpdir, fn, header, ltx, svgfile, stream, svgdata, tojupyter;

  header:=Concatenation( "\\documentclass[crop,tikz]{standalone}\n",
                "\\usepackage{pgfplots}",
                "\\makeatletter\n",
                "\\batchmode\n",
                "\\nonstopmode\n",
                "\\begin{document}",
                "\\begin{tikzpicture}");
  header:=Concatenation(header, tikz);
  header:=Concatenation(header,"\\end{tikzpicture}\n\\end{document}");

  tmpdir := DirectoryTemporary();
  fn := Filename( tmpdir, "svg_get" );

  PrintTo( Concatenation( fn, ".tex" ), header );

  ltx := Concatenation( "pdflatex -shell-escape --output-directory ",
          Filename( tmpdir, "" ), " ",
          Concatenation( fn, ".tex" ), " > ", Concatenation( fn, ".log2" ) );
  Exec( ltx );

  if not( IsExistingFile( Concatenation(fn, ".pdf") ) ) then
    tojupyter := rec( json := true, name := "stdout", 
      data := "No pdf was created; pdflatex is installed in your system?" );
  else
    svgfile := Concatenation( fn, ".svg" );
    ltx := Concatenation( "pdf2svg ", Concatenation( fn, ".pdf" ), " ",
                svgfile, " >> ", Concatenation( fn, ".log2" ) );
    Exec( ltx );

    if not( IsExistingFile( svgfile ) ) then
      tojupyter := rec( json := true, name := "stdout", 
        data := "No svg was created; pdf2svg is installed in your system?" );
    else
        stream := InputTextFile( svgfile );
        if stream <> fail then
            svgdata := ReadAll( stream );
            tojupyter := rec( json := true, source := "gap",
                            data := rec( ( "image/svg+xml" ) := svgdata ),
                            metadata := rec( ( "image/svg+xml" ) := rec( width := 500, height := 500 ) ) );
            CloseStream( stream );
        else
            tojupyter := rec( json := true, name := "stdout",
                            data := Concatenation( "Unable to render ", tikz ) );
        fi;
    fi;
  fi;

  return tojupyter;
end);


# TODO: Really we should be formatting text and HTML output
#       And the HTML output could for instance link to the 
#       documentation of the attributes
BindGlobal("JUPYTER_FormatKnown",
function(obj)
    local res, n, p, props, attrs, len;

    props := KnownPropertiesOfObject(obj);
    attrs := KnownAttributesOfObject(obj);

    len   := Maximum(List(props, Length));
    len   := Maximum(len, Maximum(List(props, Length))) + 1;

    res := "Properties:\n\n";
    props := List(props,
                  x -> STRINGIFY(String(x, -len), ": ",
                                 ValueGlobal(x)(obj)));
    Append(res, JoinStringsWithSeparator(props, "\n"));

    Append(res, "\n\nAttributes:\n\n");
    attrs := List(attrs,
                  x -> STRINGIFY(String(x, -len), ": ",
                                 ValueGlobal(x)(obj)));
    Append(res, JoinStringsWithSeparator(attrs, "\n"));
    return res;
end);

BindGlobal("JUPYTER_FindHelp",
function(ident)
    local s, matches, match, book, data, data1, lines, info;

    s := SIMPLE_STRING(ident);
    matches := HELP_GET_MATCHES(HELP_KNOWN_BOOKS[1], s, true);
    if matches[1] <> [] then
        match := matches[1][1];
    elif matches[2] <> [] then
        match := matches[2][1];
    else
        return "Undocumented";
    fi;
    book := match[1];
    info := HELP_BOOK_INFO(match[1]);

    data := HELP_BOOK_HANDLER.GapDocGAP.HelpData(info, match[2], "text");
    data1 := HELP_BOOK_HANDLER.GapDocGAP.HelpData(info, match[2] + 1, "text");

    if IsString(data.lines) then
        lines := SplitString(data.lines, "\n");
    else
        lines := data.lines;
    fi;
    return JoinStringsWithSeparator(lines{[data.start..data1.start-1]}, "\n");
end);


BindGlobal("JUPYTER_Inspect",
function(str, pos)
    local cpos, ipos, ident, ws, sep, fapp, result, found,
          var, textplain, texthtml;

    found := false;
    textplain := "";
    texthtml := "";

    # extract keyword/identifier
    # go to the left of pos
    # TODO: This should really use a GAP Parser or the
    #       SYNTAX_TREE module; SYNTAX_TREE doesn't have position
    #       information
    # Once we can parse code partially, we could even try to evaluate
    # subexpressions for help tips?

    # ( is not a separator, because we use it to
    # detect function application
    sep := [") \t\n\r;:=<>=!."];

    cpos := Minimum(pos, Length(str));
    ipos := 1;
    fapp := false;
    ident := [];

    # skip whitespace
    while cpos > 0 and (str[cpos] in " \t") do cpos := cpos - 1; od;
    while cpos > 0 and (not str[cpos] in sep) do
        if str[cpos] = '(' then
            fapp := true;
        else
            ident[ipos] := str[cpos];
            ipos := ipos + 1;
        fi;
        cpos := cpos - 1;
    od;
    ident := Reversed(ident);

    if ident <> "" then
        found := true;
        if fapp then
            # find documentation for function application
            textplain := JUPYTER_FindHelp(ident{[1..Length(ident)-1]});
        elif IsBoundGlobal(ident) then
            var := ValueGlobal(ident);
            if IsFunction(var) then
                # try finding doc?
                textplain := JUPYTER_FindHelp(ident);
            elif
                IsObject(var) then
                # Display Known Properties/Attributes/Categories/Types
                textplain := JUPYTER_FormatKnown(var);
            fi;
        fi;
    fi;
    return rec( status := "ok",
                found := found,
                data := rec( text\/html := texthtml,
                             text\/plain := textplain,
                             metadata := rec( text\/html := "",
                                              text\/plain := "" ) ) );
end);

# This is a rather basic helper function to do
# completion. It is related to the completion
# function provided in lib/cmdledit.g in the GAP
# distribution
BindGlobal("JUPYTER_Complete",
function(code, cursor_pos)
    local default, cand, i, matches, tokens, tok;

    default := rec( matches := [], cursor_start := 0,
                    cursor_end := cursor_pos, metadata := rec(),
                    status := "ok" );

    code := code{[1..cursor_pos]};
    if Length(code) = 0 then
        JUPYTER_print(default);
    fi;
    tokens := SplitString(code, "():=<>,.[]?-+*/; ");

    if tokens = [] then
        JUPYTER_print(default);
    fi;

    tok := tokens[Length(tokens)];
    cand := IDENTS_BOUND_GVARS();
    matches := Filtered(cand, i -> PositionSublist(i, tok) = 1);
    SortBy(matches, Length);
    JUPYTER_print( rec( matches := matches
                      , cursor_start := cursor_pos - Length(tok)
                      , cursor_end := cursor_pos
                      , metadata := rec()
                      , status := "ok" ) );
end);

MakeReadWriteGlobal("Print");
UnbindGlobal("Print");
BindGlobal("Print",
          function(args...)
              local str, ostream, prt;
              str := "";
              ostream := OutputTextString(str, false);
              Add(args, ostream, 1);
              CallFuncList(PrintTo, args);
              JUPYTER_print(rec( status := "ok",
                                 result := rec( name := "stdout"
                                              , text := str )));
          end);
MakeReadOnlyGlobal("Print");


# This is another ugly hack to make the GAP Help System
# play ball. Let us please fix this soon.
# TODO: This is now broken because we got rid of parsing
#       on the python side. HELP now should result
#       in a record that can be sent back to jupyter
#       as a JSON string
HELP_VIEWER_INFO.jupyter_online :=
    rec(
         type := "url",
         show := function( data )
             # data[1] is the text preceding the hyperlink (name of the help book),
             # data[2] is the text to be linked, and data[3] is the URL
             local p,r;

             p := data[3];

             for r in GAPInfo.RootPaths do
                 p := ReplacedString(data[3], r, "http://www.gap-system.org/Manuals/");
             od;
             return rec( json := true
                       , source := "gap"
                       , data := rec( ("text/html") := Concatenation( data[1], ": <a target=\"_blank\" href=\"", p, "\">", data[2], "</a>") ) );
         end
        );

HELP_VIEWER_INFO.jupyter_local :=
    rec(
         type := "url",
         show := function( data )
             # data[1] is the text preceding the hyperlink (name of the help book),
             # data[2] is the text to be linked, and data[3] is the URL
             local p,r;

             p := data[3];

             for r in GAPInfo.RootPaths do
                 p := ReplacedString(data[3], r, "/");
             od;
             return rec( json := true
                       , source := "gap"
                       , data := rec( ("text/html") := Concatenation( data[1], ": <a target=\"_blank\" href=\"files", p, "\">", data[2], "</a>") ) );
         end
        );

DeclareGlobalFunction("GET_HELP_URL");

#############################################################################
##
#F  GET_HELP_URL( <match> ) . . . . . .  print the url for the help section
##
##  Based on HELP_PRINT_MATCH
##
##  <match> is [book, entrynr]
##
InstallGlobalFunction(GET_HELP_URL, function(match)
local book, entrynr, viewer, hv, pos, type, data;
  book := HELP_BOOK_INFO(match[1]);
  entrynr := match[2];
  viewer:= UserPreference("HelpViewers");
  if HELP_LAST.NEXT_VIEWER = false then
    hv := viewer;
  else
    pos := Position( viewer, HELP_LAST.VIEWER );
    if pos = fail then
      hv := viewer;
    else
      hv := viewer{Concatenation([pos+1..Length(viewer)],[1..pos])};
    fi;
    HELP_LAST.NEXT_VIEWER := false;
  fi;
  for viewer in hv do
    # type of data we need now depends on help viewer
    type := HELP_VIEWER_INFO.(viewer).type;
    # get the data via appropriate handler
    data := HELP_BOOK_HANDLER.(book.handler).HelpData(book, entrynr, type);
    if data <> fail then
      # show the data
      return HELP_VIEWER_INFO.(viewer).show(
        [ book.bookname, StripEscapeSequences(book.entries[entrynr][1]), data]);
          # name of the help book, the text to be linked, and the URL
    else
      return rec( json := true
                  , source := "gap"
                  , data := rec( ("text/html") := Concatenation(
                      book.bookname, ": ", StripEscapeSequences(book.entries[entrynr][1]),
                     " - no html help available. Please check other formats!" ) ) );
    fi;
    HELP_LAST.VIEWER := viewer;
  od;
  HELP_LAST.BOOK := book;
  HELP_LAST.MATCH := entrynr;
  HELP_LAST.VIEWER := viewer;
  return true;
end);


MakeReadWriteGlobal("HELP_SHOW_MATCHES");
UnbindGlobal("HELP_SHOW_MATCHES");
DeclareGlobalFunction("HELP_SHOW_MATCHES");
InstallGlobalFunction(HELP_SHOW_MATCHES, function( books, topic, frombegin )
local   exact,  match,  x,  lines,  cnt,  i,  str,  n, res;

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
    return GET_HELP_URL(i);

  # more than one topic found, show overview in pager
  else
    lines :=
        ["","Help: several entries match this topic - type ?2 to get match [2]\n"];
        # there is an empty line in the beginning since `tail' will start from line 2
    HELP_LAST.TOPICS:=[];
    cnt := 0;
    # show exact matches first
    match := Concatenation(exact, match);
    res:="";
    for i  in match  do
      cnt := cnt+1;
      topic := Concatenation(i[1].bookname,": ",i[1].entries[i[2]][1]);
      Add(HELP_LAST.TOPICS, i);
      Append(res, GET_HELP_URL(i).data.("text/html"));
      Append(res, "<br/>");
    od;
    return rec( json := true
                , source := "gap"
                , data := rec( ("text/html") := res ) );
  fi;
end);


MakeReadWriteGlobal("HELP");
UnbindGlobal("HELP");
DeclareGlobalFunction("HELP");
InstallGlobalFunction(HELP, function( str )
  local origstr, nwostr, p, book, books, move, add;

  origstr := ShallowCopy(str);
  nwostr := NormalizedWhitespace(origstr);

  # extract the book
  p := Position( str, ':' );
  if p <> fail  then
      book := str{[1..p-1]};
      str  := str{[p+1..Length(str)]};
  else
      book := "";
  fi;

  # normalizing for search
  book := SIMPLE_STRING(book);
  str := SIMPLE_STRING(str);

  # we check if `book' MATCH_BEGINs some of the available books
  books := Filtered(HELP_KNOWN_BOOKS[1], bn-> MATCH_BEGIN(bn, book));
  if Length(book) > 0 and Length(books) = 0 then
    Print("Help: None of the available books matches (try: '?books').\n");
    return;
  fi;

  # function to add a topic to the ring
  move := false;
  add  := function( books, topic )
      if not move  then
          HELP_RING_IDX := (HELP_RING_IDX+1) mod HELP_RING_SIZE;
          HELP_BOOK_RING[HELP_RING_IDX+1]  := books;
          HELP_TOPIC_RING[HELP_RING_IDX+1] := topic;
      fi;
  end;

  # if the topic is empty show the last shown one again
  if  book = "" and str = ""  then
       if HELP_LAST.BOOK = 0 then
         HELP("Tutorial: Help");
       else
         return GET_HELP_URL( [HELP_LAST.BOOK, HELP_LAST.MATCH] );
       fi;
       return;

  # if topic is "&" shobn;w last topic again, but with next viewer in viewer
  # list, or with last viewer again if there is no next one
  elif book = "" and str = "&" and Length(nwostr) = 1 then
       if HELP_LAST.BOOK = 0 then
         HELP("Tutorial: Help");
       else
         HELP_LAST.NEXT_VIEWER := true;
         return GET_HELP_URL( [HELP_LAST.BOOK, HELP_LAST.MATCH] );
       fi;
       return;

  # if the topic is '-' we are interested in the previous search again
  elif book = "" and str = "-" and Length(nwostr) = 1  then
      HELP_RING_IDX := (HELP_RING_IDX-1) mod HELP_RING_SIZE;
      books := HELP_BOOK_RING[HELP_RING_IDX+1];
      str  := HELP_TOPIC_RING[HELP_RING_IDX+1];
      move := true;

  # if the topic is '+' we are interested in the last section again
  elif book = "" and str = "+" and Length(nwostr) = 1  then
      HELP_RING_IDX := (HELP_RING_IDX+1) mod HELP_RING_SIZE;
      books := HELP_BOOK_RING[HELP_RING_IDX+1];
      str  := HELP_TOPIC_RING[HELP_RING_IDX+1];
      move := true;
  fi;

  # number means topic from HELP_LAST.TOPICS list
  if book = "" and ForAll(str, a-> a in "0123456789") then
      HELP_SHOW_FROM_LAST_TOPICS(Int(str));

  # if the topic is '<' we are interested in the one before 'LastTopic'
  elif book = "" and str = "<" and Length(nwostr) = 1  then
      HELP_SHOW_PREV();

  # if the topic is '>' we are interested in the one after 'LastTopic'
  elif book = "" and str = ">" and Length(nwostr) = 1  then
      HELP_SHOW_NEXT();

  # if the topic is '<<' we are interested in the previous chapter intro
  elif book = "" and str = "<<"  then
      HELP_SHOW_PREV_CHAPTER();

  # if the topic is '>>' we are interested in the next chapter intro
  elif book = "" and str = ">>"  then
      HELP_SHOW_NEXT_CHAPTER();

  # if the subject is 'Welcome to GAP' display a welcome message
  elif book = "" and str = "welcome to gap"  then
      if HELP_SHOW_WELCOME(book)  then
          add( books, "Welcome to GAP" );
      fi;

  # if the topic is 'books' display the table of books
  elif book = "" and str = "books"  then
      if HELP_SHOW_BOOKS()  then
          add( books, "books" );
      fi;

  # if the topic is 'chapters' display the table of chapters
  elif str = "chapters"  or str = "contents" or book <> "" and str = "" then
      if ForAll(books, b->  HELP_SHOW_CHAPTERS(b)) then
        add( books, "chapters" );
      fi;

  # if the topic is 'sections' display the table of sections
  elif str = "sections"  then
      if ForAll(books, b-> HELP_SHOW_SECTIONS(b)) then
        add(books, "sections");
      fi;

  # if the topic is '?<string>' search the index for any entries for
  # which <string> is a substring (as opposed to an abbreviation)
  elif Length(str) > 0 and str[1] = '?'  then
      str := str{[2..Length(str)]};
      NormalizeWhitespace(str);
      return HELP_SHOW_MATCHES( books, str, false);

  # search for this topic
  elif IsRecord( HELP_SHOW_MATCHES( books, str, true ) ) then
      return HELP_SHOW_MATCHES( books, str, true );
  elif origstr in NAMES_SYSTEM_GVARS then
      Print( "Help: '", origstr, "' is currently undocumented.\n",
             "      For details, try ?Undocumented Variables\n" );
  elif book = "" and
                 ForAny(HELP_KNOWN_BOOKS[1], bk -> MATCH_BEGIN(bk, str)) then
      Print( "Help: Are you looking for a certain book? (Trying '?", origstr,
             ":' ...\n");
      return HELP( Concatenation(origstr, ":") );
  else
     # seems unnecessary, since some message is already printed in all
     # cases above (?):
     # Print( "Help: Sorry, could not find a match for '", origstr, "'.\n");
  fi;
end);

SetUserPreference("browse", "SelectHelpMatches", false);
SetUserPreference("Pager", "tail");
SetUserPreference("PagerOptions", "");
# This is of course complete nonsense if you're running the jupyter notebook
# on your local machine.
SetHelpViewer("jupyter_online");
