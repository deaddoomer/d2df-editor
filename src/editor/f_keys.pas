unit f_keys;

{$INCLUDE ../shared/a_modes.inc}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls;

type
  TKeysForm = class (TForm)
    cbRedKey: TCheckBox;
    cbGreenKey: TCheckBox;
    cbBlueKey: TCheckBox;
    cbRedTeam: TCheckBox;
    cbBlueTeam: TCheckBox;
    bOK: TButton;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KeysForm: TKeysForm;

implementation

{$R *.lfm}

end.
