{$MODE DELPHI}

{$INLINE ON}

{$WARNINGS ON}
{$NOTES ON}

{$IFDEF MSWINDOWS}
  {$IFNDEF WINDOWS}
    {$DEFINE WINDOWS}
  {$ENDIF WINDOWS}
{$ENDIF MSWINDOWS}

{$IF DEFINED(CPU64) OR NOT DEFINED(WINDOWS)}
  {$DEFINE NOSOUND}
{$ENDIF}
