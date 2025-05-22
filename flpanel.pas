{$MODE OBJFPC}{$H+}
unit flpanel;

interface

uses
  Objects, UViews, UDrivers, flpanelx, SysUtils, {$IFDEF UNIX}BaseUnix, Unix,{$ELSE}Dos,{$ENDIF} Classes;

type
  PFilePanel = ^TFilePanel;
  TFilePanel = object(TFilePanelRoot)
  public
    PanelID: String[10];
    FileList: TStringList;
    CurrentDir: String; // Заменили PathStr на String

    // Явно указываем Objects.TRect
    constructor Init(var Bounds: Objects.TRect; ADrive: Integer; AScrBar: PScrollBar);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure LoadDirectoryListing(const Path: String); // Заменили PathStr
  end;

implementation

constructor TFilePanel.Init(var Bounds: Objects.TRect; ADrive: Integer; AScrBar: PScrollBar);
begin
  inherited Init(Bounds, ADrive, AScrBar); // Теперь типы должны совпадать
  Options := Options or ofFramed;
  FileList := TStringList.Create;
  FileList.Sorted := True;

  if ADrive = 0 then
    PanelID := 'Left PNL'
  else
    PanelID := 'Right PNL';

  {$IFDEF UNIX}
  CurrentDir := GetCurrentDir + '/';
  {$ELSE}
  GetDir(0, CurrentDir);
  if CurrentDir[Length(CurrentDir)] <> '\' then
    CurrentDir := CurrentDir + '\';
  {$ENDIF}
  LoadDirectoryListing(CurrentDir);
end;

destructor TFilePanel.Done;
begin
  FileList.Free;
  inherited Done;
end;

procedure TFilePanel.LoadDirectoryListing(const Path: String);
var
  SearchRec: TSearchRec;
  Res: Integer;
  {$IFDEF UNIX}
  FindPath: String;
  {$ENDIF}
begin
  FileList.Clear;
  CurrentDir := Path;

  {$IFDEF UNIX}
  FindPath := Path;
  // Для Unix, если Path не заканчивается на '/', добавляем его
  if (Length(FindPath) > 0) and (FindPath[Length(FindPath)] <> '/') then
  begin
    FindPath := FindPath + '/';
  end;
  Res := FindFirst(FindPath + '*', faAnyFile, SearchRec);
  {$ELSE}
  Res := FindFirst(Path + '*.*', faAnyFile, SearchRec);
  {$ENDIF}

  while Res = 0 do
  begin
    if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
    begin
      if (SearchRec.Attr and faDirectory) <> 0 then
        FileList.Add('[ ' + SearchRec.Name + ' ]')
      else
        FileList.Add(SearchRec.Name);
    end;
    Res := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
  DrawView;
end;

procedure TFilePanel.Draw;
var
  B: TDrawBuffer;
  ColorValue, TextColor: Byte;
  S: String;
  i, YPos: Integer;
begin
  inherited Draw;

  ColorValue := GetColor($0201);
  TextColor := GetColor($0701);

  for YPos := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', ColorValue, Size.X);
    WriteLine(0, YPos, Size.X, 1, B);
  end;

  YPos := 0;
  for i := 0 to FileList.Count - 1 do
  begin
    if YPos >= Size.Y then Break;

    S := FileList[i];
    if Length(S) > Size.X - 2 then
      S := Copy(S, 1, Size.X - 2);

    MoveChar(B, ' ', TextColor, Size.X);
    MoveStr(B, S, TextColor);
    WriteLine(1, YPos, Size.X - 2, 1, B);
    Inc(YPos);
  end;

  S := PanelID + ' Path: ' + CurrentDir;
  if Length(S) > Size.X - 2 then S := Copy(S,1, Size.X - 2);
  MoveChar(B, ' ', TextColor, Size.X);
  MoveStr(B, S, TextColor);
  if Size.Y > 0 then
      WriteLine(1, Size.Y - 1, Size.X - 2, 1, B);
end;

end.