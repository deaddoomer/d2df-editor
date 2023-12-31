unit e_log;

{$INCLUDE ../shared/a_modes.inc}

interface

uses
  SysUtils;

type
  TWriteMode=(WM_NEWFILE,  WM_OLDFILE);
  TRecordCategory=(MSG_FATALERROR, MSG_WARNING, MSG_NOTIFY);

procedure e_InitLog(fFileName: String; fWriteMode: TWriteMode);
procedure e_WriteLog(TextLine: String; RecordCategory: TRecordCategory;
                     WriteTime: Boolean = True);
procedure e_WriteStackTrace (const msg: AnsiString);
function DecodeIPV4(ip: LongWord): string;

implementation

var
  FirstRecord: Boolean;
  FileName: String;

{ TLog }

function DecodeIPV4(ip: LongWord): string;
begin
  Result := Format('%d.%d.%d.%d', [ip and $FF, (ip shr 8) and $FF, (ip shr 16) and $FF, (ip shr 24)]);
end;

procedure e_WriteLog(TextLine: String; RecordCategory: TRecordCategory;
                     WriteTime: Boolean = True);
var
  LogFile: TextFile;
  Prefix: ShortString;
begin
  if FileName = '' then Exit;

  Assign(LogFile, FileName);
  if FileExists(FileName) then
    Append(LogFile)
  else
    Rewrite(LogFile);
  if FirstRecord then
  begin
    Writeln(LogFile, '--- Log started at '+TimeToStr(Time)+' ---');
    FirstRecord := False;
  end;
  case RecordCategory of
    MSG_FATALERROR: Prefix := '!!!';
    MSG_WARNING:    Prefix := '!  ';
    MSG_NOTIFY:     Prefix := '***';
  end;
  if WriteTime then
    Writeln(LogFile, '['+TimeToStr(Time)+'] '+Prefix+' '+TextLine)
  else
    Writeln(LogFile, Prefix+' '+TextLine);
  Close(LogFile);
end;

{$I-}
procedure e_WriteStackTrace (const msg: AnsiString);
  var LogFile: TextFile;
begin
  e_WriteLog(msg, TRecordCategory.MSG_FATALERROR);

  Assign(LogFile, FileName);
  if FileExists(FileName) then
    Append(LogFile)
  else
    Rewrite(LogFile);

  writeln(LogFile, '=====================');
  DumpExceptionBackTrace(LogFile);

  Close(LogFile);
end;

procedure e_InitLog(fFileName: String; fWriteMode: TWriteMode);
begin
 FileName := fFileName;
 if fWriteMode = WM_NEWFILE then
  if FileExists(FileName) then
   DeleteFile(FileName);
 FirstRecord := True;
end;

end.
