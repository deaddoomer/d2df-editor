unit f_packmap;

{$INCLUDE ../shared/a_modes.inc}

interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, utils;

type
  TPackMapForm = class (TForm)
    bPack: TButton;
    SaveDialog: TSaveDialog;
    Panel1: TPanel;
  // Сохранить в:
    LabelSaveTo: TLabel;
    eWAD: TEdit;
    bSelectWAD: TButton;
  // Имя карты:
    LabelMapName: TLabel;
    eResource: TEdit;
  // Текстуры:
    cbTextrures: TCheckBox;
    LabelTextures: TLabel;
    eTSection: TEdit;
  // Небо:
    cbSky: TCheckBox;
    LabelSky: TLabel;
    eSSection: TEdit;
  // Музыка:
    cbMusic: TCheckBox;
    LabelMusic: TLabel;
    eMSection: TEdit;
  // Дополнительно:
    cbAdd: TCheckBox;
    cbNonStandart: TCheckBox;
    
    procedure bSelectWADClick(Sender: TObject);
    procedure bPackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PackMapForm: TPackMapForm;

implementation

uses
  BinEditor, WADEDITOR, g_map, MAPREADER, MAPWRITER, MAPSTRUCT,
  f_main, math, g_language, g_options, e_log;

{$R *.lfm}

const
  STANDART_WAD = 'standart.wad';
  SHRSHADE_WAD = 'shrshade.wad';


procedure TPackMapForm.bSelectWADClick(Sender: TObject);
begin
  SaveDialog.Filter := MsgFileFilterWad;

  if SaveDialog.Execute() then
    eWAD.Text := SaveDialog.FileName;
end;

function ProcessResource(wad_to: TWADEditor_1; section_to, filename, section, resource: String): Boolean;
var
  wad2: TWADEditor_1;
  data: Pointer;
  reslen: Integer;
  //s: string;

begin
  Result := False;

  if filename = '' then
    g_ProcessResourceStr(OpenedMap, @filename, nil, nil)
  else
    filename := WadsDir + DirectorySeparator + filename;

// Читаем ресурс из WAD-файла карты или какого-то другого:
  wad2 := TWADEditor_1.Create();

  if not wad2.ReadFile(filename) then
  begin
    Application.MessageBox(PChar(Format(MsgMsgWadError, [ExtractFileName(filename)])), PChar(MsgMsgError), MB_OK + MB_ICONERROR);
    wad2.Free();
    Exit;
  end;

  if not wad2.GetResource(utf2win(section), utf2win(resource), data, reslen) then
  begin
    Application.MessageBox(PChar(Format(MsgMsgResError, [filename, section, resource])), PChar(MsgMsgError), MB_OK + MB_ICONERROR);
    wad2.Free();
    Exit;
  end;

  wad2.Free();

 {if wad_to.HaveResource(utf2win(section_to), utf2win(resource)) then
 begin
  for a := 2 to 256 do
  begin
   s := IntToStr(a);
   if not wad_to.HaveResource(utf2win(section_to), utf2win(resource+s)) then Break;
  end;
  resource := resource+s;
 end;}

// Если такого ресурса нет в WAD-файле-назначении, то копируем:
  if not wad_to.HaveResource(utf2win(section_to), utf2win(resource)) then
  begin
    if not wad_to.HaveSection(utf2win(section_to)) then
      wad_to.AddSection(utf2win(section_to));
    wad_to.AddResource(data, reslen, utf2win(resource), utf2win(section_to));
  end;

  FreeMem(data);

  Result := True;
end;

procedure TPackMapForm.bPackClick(Sender: TObject);
var
  WAD: TWADEditor_1;
  mr: TMapReader_1;
  mw: TMapWriter_1;
  data: Pointer;
  len: LongWord;
  textures: TTexturesRec1Array;
  header: TMapHeaderRec_1;
  a: Integer;
  res, tsection, ssection, msection, filename, section, resource: String;

begin
  if eWAD.Text = '' then
    Exit;
  if eResource.Text = '' then
    Exit;

  tsection := eTSection.Text;
  ssection := eSSection.Text;
  msection := eMSection.Text;

// Сохраняем карту в память:
  data := SaveMap('', '');
  if data = nil then
    Exit;

  WAD := TWADEditor_1.Create();

// Не перезаписывать WAD, а дополнить:
  if cbAdd.Checked then
    if WAD.ReadFile(eWAD.Text) then
      WAD.CreateImage();

// Читаем карту из памяти:
  mr := TMapReader_1.Create();
  mr.LoadMap(data);
  FreeMem(data);

// Получаем текстуры:
  textures := mr.GetTextures();

// Нужно копировать текстуры:
  if cbTextrures.Checked and (textures <> nil) then
    for a := 0 to High(textures) do
    begin
      res := win2utf(textures[a].Resource);
      if IsSpecialTexture(res) then
        Continue;

      g_ProcessResourceStr(res, @filename, @section, @resource);

    // Не записывать стандартные текстуры:
      if (not cbNonStandart.Checked) or
         ( (AnsiLowerCase(filename) <> STANDART_WAD) and
           (AnsiLowerCase(filename) <> SHRSHADE_WAD) ) then
      begin
      // Копируем ресурс текстуры:
        if not f_packmap.ProcessResource(WAD, tsection, filename, section, resource) then
        begin
          mr.Free();
          WAD.Free();
          Exit;
        end;

      // Переименовываем ресурс текстуры:
        res := utf2win(Format(':%s\%s', [tsection, resource]));
        ZeroMemory(@textures[a].Resource[0], 64);
        CopyMemory(@textures[a].Resource[0], @res[1], Min(Length(res), 64));
      end;
    end;

// Получаем заголовок карты:
  header := mr.GetMapHeader();

// Нужно копировать небо:
  if cbSky.Checked then
  begin
    res := win2utf(header.SkyName);
    g_ProcessResourceStr(res, @filename, @section, @resource);

  // Не записывать стандартное небо:
    if (not cbNonStandart.Checked) or
       ( (AnsiLowerCase(filename) <> STANDART_WAD) and
         (AnsiLowerCase(filename) <> SHRSHADE_WAD) ) then
    begin
    // Копируем ресурс неба:
      if not f_packmap.ProcessResource(WAD, ssection, filename, section, resource) then
      begin
        mr.Free();
        WAD.Free();
        Exit;
      end;

    // Переименовываем ресурс неба:
      res := utf2win(Format(':%s\%s', [ssection, resource]));
      ZeroMemory(@header.SkyName[0], 64);
      CopyMemory(@header.SkyName[0], @res[1], Min(Length(res), 64));
    end;
  end;

// Нужно копировать музыку:
  if cbMusic.Checked then
  begin
    res := win2utf(header.MusicName);
    g_ProcessResourceStr(res, @filename, @section, @resource);

  // Не записывать стандартную музыку:
    if (not cbNonStandart.Checked) or
       ( (AnsiLowerCase(filename) <> STANDART_WAD) and
         (AnsiLowerCase(filename) <> SHRSHADE_WAD) ) then
    begin
    // Копируем ресурс музыки:
      if not f_packmap.ProcessResource(WAD, msection, filename, section, resource) then
      begin
        mr.Free();
        WAD.Free();
        Exit;
      end;

    // Переименовываем ресурс музыки:
      res := utf2win(Format(':%s\%s', [msection, resource]));
      ZeroMemory(@header.MusicName[0], 64);
      CopyMemory(@header.MusicName[0], @res[1], Min(Length(res), 64));
    end;
  end;

  {
// Нужно копировать дополнительные текстуры:
  if cbTextrures.Checked and (textures <> nil) and
     (gPanels <> nil) and (gTriggers <> nil) then
  begin
    for a := 0 to High(gPanels) do
    begin
      ok := False;

    // Ссылаются ли на эту панель триггеры:
      for b := 0 to High(gTriggers) do
        if ( (gTriggers[b].TriggerType in [TRIGGER_OPENDOOR,
                TRIGGER_CLOSEDOOR, TRIGGER_DOOR, TRIGGER_DOOR5,
                TRIGGER_CLOSETRAP, TRIGGER_TRAP, TRIGGER_LIFTUP,
                TRIGGER_LIFTDOWN, TRIGGER_LIFT]) and
             (gTriggers[b].Data.PanelID = a) ) or
           (gTriggers[b].TexturePanel = a) then
        begin
          ok := True;
          Break;
        end;

    // Есть триггеры на эту панель:
      if ok and (gPanels[a].TextureName <> '') and
         (not IsSpecialTexture(gPanels[a].TextureName) and
         g_Texture_NumNameFindStart(gPanels[a].TextureName) then
      begin
        while True do
        begin
          r := g_Texture_NumNameFindNext(res);
          case r of
            NNF_NAME_FOUND: ;
            NNF_NAME_EQUALS: Continue;
            else Break;
          end;

          if res = '' then
            Break;

          g_ProcessResourceStr(res, @filename, @section, @resource);

        // Не записывать стандартные дополнительные текстуры:
          if (not cbNonStandart.Checked) or
             ( (AnsiLowerCase(filename) <> STANDART_WAD) and
               (AnsiLowerCase(filename) <> SHRSHADE_WAD) ) then
          begin
          // Копируем ресурс дополнительной текстуры:
            if f_packmap.ProcessResource(WAD, tsection, filename, section, resource) then
            begin

              Нужно проверять есть такая текстура textures и есть ли она вообще?
            // Переименовываем ресурс текстуры:
              res := utf2win(Format(':%s\%s', [tsection, resource]));
              ZeroMemory(@textures[a].Resource[0], 64);
              CopyMemory(@textures[a].Resource[0], @res[1], Min(Length(res), 64));



            end;
          end;
        end; // while True
      end;
    end;
  end;
  }

// Записываем изменения карты:
  mw := TMapWriter_1.Create();

  mw.AddHeader(header);
  mw.AddTextures(textures);
  mw.AddPanels(mr.GetPanels());
  mw.AddItems(mr.GetItems());
  mw.AddAreas(mr.GetAreas());
  mw.AddMonsters(mr.GetMonsters());
  mw.AddTriggers(mr.GetTriggers());

// Сохраняем карту из памяти под новым именем в WAD-файл:
  len := mw.SaveMap(data);
  WAD.AddResource(data, len, eResource.Text, '');
  WAD.SaveTo(eWAD.Text);

  mw.Free();
  mr.Free();
  WAD.Free();

  MessageDlg(Format(MsgMsgPacked, [eResource.Text, ExtractFileName(eWAD.Text)]), mtInformation, [mbOK], 0);
  Close();
end;

procedure TPackMapForm.FormCreate(Sender: TObject);
begin
  SaveDialog.InitialDir := MapsDir;
end;

end.
