#  Unbind(PrintPromptHook);
  BindGlobal("PrintPromptHook",
  function()
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
  end);
