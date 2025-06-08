{/////////////////////////////////////////////////////////////////////////
//
//  dn3l — an LLM-assisted recreation of Dos Navigator.
//  Copyright (C) 2025 dn3l Contributors.
//
//  The development of this code involved significant use of Large
//  Language Models (LLMs), which were provided with the original
//  source code of Dos Navigator Version 1.51 as a reference and basis,
//  so this work should be considered a derivative work of Dos Navigator
//  and, as such, is governed by the terms of the original Dos Navigator
//  license, provided below. All terms of the original license
//  must be adhered to.
//
//  All source code files originating from or directly based on Borland's
//  Turbo Vision library were excluded from the original Dos Navigator
//  codebase before it was presented to the Large Language Models.
//  Any Turbo Vision-like functionality within this dn3l project
//  has been reimplemented or is based on alternative, independently
//  sourced solutions.
//
//  Consequently, direct porting of code from the original Dos Navigator
//  1.51 source into this dn3l project is permissible, provided that
//  such ported code segments do not originate from, nor are directly
//  based on, Borland's Turbo Vision library. Any such directly
//  ported code will also be governed by the Dos Navigator license terms.
//
//  All code within this project, whether LLM-assisted, manually written,
//  or modified by project contributors, is subject to the terms
//  of the Dos Navigator license specified below.
//
//  Redistributions of source code must retain this notice.
//
//  Original Dos Navigator Copyright Notice:
//
//////////////////////////////////////////////////////////////////////////}

{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on Dos Navigator by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

unit flpanel;

interface

uses
  UViews, Objects, UDrivers, UDialogs,
  Dos,
  SysUtils, // For PathDelim, ExtractFilePath, ChDir, GetCurrentDir, etc.
  DNLogger,
  utf8utils; // See https://gitlab.com/freepascal.org/fpc/source/-/issues/41269

type
  PFileListItem = ^TFileListItem;
  TFileListItem = object(TObject)
    FileName: String;
    IsDirectory: Boolean;
    constructor Init(const AFileName: String; AIsDirectory: Boolean);
    destructor Done; virtual;
  end;

  PFileListCollection = ^TFileListCollection;
  TFileListCollection = object(TCollection)
    constructor Init;
  end;

  PFilePanel = ^TFilePanel;
  TFilePanel = object(TGroup)
  public
    FileList: PFileListCollection;
    CurrentPath: String;
    FocusedItemIndex: Integer; // Index of the currently focused item
    TopItemIndex: Integer;     // Index of the item displayed at the top (for scrolling later)

    constructor Init(var Bounds: TRect);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual; // To handle keyboard
    procedure LoadDirectory(const Path: String);
    procedure SetFocus(NewFocusIndex: Integer);
  private
    procedure DrawItem(Y: Integer; Index: Integer; IsFocused: Boolean; var B: TDrawBuffer);
    procedure ChangeDirectory(const NewPath: String);
    procedure ExecuteFocusedItem;
  end;

implementation

uses FVConsts; // For key codes like kbUp, kbDown, kbEnter

{ TFileListItem }

constructor TFileListItem.Init(const AFileName: String; AIsDirectory: Boolean);
begin
  inherited Init;
  FileName := AFileName;
  IsDirectory := AIsDirectory;
end;

destructor TFileListItem.Done;
begin
  inherited Done;
end;

{ TFileListCollection }

constructor TFileListCollection.Init;
begin
  inherited Init(20, 10); // Increased initial capacity and delta
end;

{ TFilePanel }

constructor TFilePanel.Init(var Bounds: TRect);
var
  InitialPath: String;
begin
  Logger.Log('  TFilePanel.Init starting...');
  Logger.Log('  Initial Bounds for TFilePanel', Bounds);

  inherited Init(Bounds);
  Options := Options or ofFramed or ofSelectable or ofBuffered or ofFirstClick;
  GrowMode := gfGrowAll;
  EventMask := EventMask or evKeyDown; // We need to process key presses

  FileList := New(PFileListCollection, Init);
  FocusedItemIndex := 0;
  TopItemIndex := 0;

  {$I-}
  CurrentPath := SysUtils.GetCurrentDir; // Using SysUtils for more robust current dir
  {$I+}
  if IOResult <> 0 then
    CurrentPath := '.' + PathDelim;

  CurrentPath := IncludeTrailingPathDelimiter(CurrentPath);
  LoadDirectory(CurrentPath);

  Logger.Log('  TFilePanel.Init finished. Options', Options);
end;

destructor TFilePanel.Done;
begin
  Logger.Log('  TFilePanel.Done starting for panel at', Origin);
  if Assigned(FileList) then
    Dispose(FileList);
  inherited Done;
  Logger.Log('  TFilePanel.Done finished for panel at', Origin);
end;

procedure TFilePanel.LoadDirectory(const Path: String);
var
  SR: TRawbyteSearchRec;
  Item: PFileListItem;
  DirToList: String;
  TempPath: String;
  IsRoot: Boolean;
begin
  TempPath := ExpandFileName(Path); // Ensure we have an absolute path
  Logger.Log('  TFilePanel.LoadDirectory: Loading path', TempPath);

  if not DirectoryExists(TempPath) then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: Path does not exist or is not a directory', TempPath);
    if Assigned(FileList) then FileList^.FreeAll;
    Item := New(PFileListItem, Init('<Path not found: ' + TempPath + '>', False));
    FileList^.Insert(Item);
    CurrentPath := TempPath; // Still set CurrentPath to what was attempted
    FocusedItemIndex := 0;
    TopItemIndex := 0;
    if GetState(sfVisible) then DrawView;
    Exit;
  end;

  if Assigned(FileList) then
    FileList^.FreeAll
  else
    FileList := New(PFileListCollection, Init);

  CurrentPath := IncludeTrailingPathDelimiter(TempPath);
  DirToList := CurrentPath + '*';

  // Determine if it's a root path
  IsRoot := False;
  if Length(CurrentPath) = 1 then // Root of current drive on Unix-like systems
    IsRoot := (CurrentPath[1] = PathDelim)
  else if Length(CurrentPath) = 3 then // C:\ on DOS/Windows
    IsRoot := (CurrentPath[2] = ':') and (CurrentPath[3] = PathDelim);
  {$IFDEF UNIX}
  // For Unix, / is root, /foo/ is not
  if (CurrentPath = PathDelim) then IsRoot := True;
  {$ENDIF}


  if not IsRoot then
  begin
    Item := New(PFileListItem, Init('..', True));
    FileList^.Insert(Item);
  end;

  {$I-}
  FindFirst(DirToList, faAnyFile, SR);
  {$I+}
  if DosError <> 0 then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: FindFirst failed for', DirToList);
    Logger.Log('  DOS Error', DosError);
    Item := New(PFileListItem, Init('<Error reading directory: ' + IntToStr(DosError) + '>', False));
    FileList^.Insert(Item);
    FocusedItemIndex := 0;
    TopItemIndex := 0;
    if GetState(sfVisible) then DrawView;
    Exit;
  end;

  repeat
    if (SR.Name <> '.') and (SR.Name <> '..') then
    begin
      Item := New(PFileListItem, Init(SR.Name, (SR.Attr and faDirectory) <> 0));
      FileList^.Insert(Item);
    end;
  until FindNext(SR) <> 0;
  FindClose(SR);
  {$I+}

  FocusedItemIndex := 0;
  TopItemIndex := 0;
  if FileList^.Count > 0 then
  begin
     if (not IsRoot) and (PFileListItem(FileList^.At(0))^.FileName = '..') then
        FocusedItemIndex := 0 // Focus ".." by default if present
     else
        FocusedItemIndex := 0; // Otherwise first actual item
  end;

  Logger.Log('  TFilePanel.LoadDirectory: Found items', FileList^.Count);
  if GetState(sfVisible) then DrawView; // Redraw if panel is visible
end;

procedure TFilePanel.SetFocus(NewFocusIndex: Integer);
begin
  if (FileList = nil) or (FileList^.Count = 0) then
  begin
    FocusedItemIndex := 0;
    Exit;
  end;

  if NewFocusIndex < 0 then
    FocusedItemIndex := 0
  else if NewFocusIndex >= FileList^.Count then
    FocusedItemIndex := FileList^.Count - 1
  else
    FocusedItemIndex := NewFocusIndex;

  // Basic scrolling logic (will be improved later)
  if FocusedItemIndex < TopItemIndex then
    TopItemIndex := FocusedItemIndex;
  if FocusedItemIndex >= TopItemIndex + (Size.Y - 2) then // -2 for frame
    TopItemIndex := FocusedItemIndex - (Size.Y - 2) + 1;

  if GetState(sfVisible) then DrawView;
end;

procedure TFilePanel.ChangeDirectory(const NewPath: String);
var
  OldPath: String;
  FocusName: String;
  I: Integer;
begin
  OldPath := CurrentPath;
  FocusName := '';

  if NewPath = '..' then
  begin
    if (Length(CurrentPath) > 0) and
       not ((Length(CurrentPath) = 1) and (CurrentPath[1] = DirectorySeparator)) and
       not ((Length(CurrentPath) = 3) and (CurrentPath[2] = ':') and (CurrentPath[3] = DirectorySeparator)) then
    begin
      FocusName := ExtractFileName(ExcludeTrailingPathDelimiter(CurrentPath));
      LoadDirectory(ExtractFilePath(ExcludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(CurrentPath))) + PathDelim);
    end;
  end else
  begin
    LoadDirectory(NewPath);
  end;

  // Try to restore focus to the directory we came from, or the first item
  if FocusName <> '' then
  begin
    for I := 0 to FileList^.Count - 1 do
    begin
      if PFileListItem(FileList^.At(I))^.FileName = FocusName then
      begin
        SetFocus(I);
        Exit;
      end;
    end;
  end;
  SetFocus(0); // Default to first item if previous dir not found or not applicable
end;

procedure TFilePanel.ExecuteFocusedItem;
var
  Item: PFileListItem;
  NewPath: String;
begin
  if (FileList = nil) or (FileList^.Count = 0) or
     (FocusedItemIndex < 0) or (FocusedItemIndex >= FileList^.Count) then
    Exit;

  Item := PFileListItem(FileList^.At(FocusedItemIndex));
  if Item = nil then Exit;

  Logger.Log('  TFilePanel.ExecuteFocusedItem: Item', Item^.FileName);
  Logger.Log('  TFilePanel.ExecuteFocusedItem: IsDirectory', Item^.IsDirectory);

  if Item^.IsDirectory then
  begin
    if Item^.FileName = '..' then
    begin
      ChangeDirectory('..');
    end
    else
    begin
      NewPath := IncludeTrailingPathDelimiter(CurrentPath + Item^.FileName);
      ChangeDirectory(NewPath);
    end;
  end
  else
  begin
    // This is a file
    Logger.Log('  TFilePanel.ExecuteFocusedItem: Attempting to "open" file', Item^.FileName);
    // Later, this would call an external viewer/editor or internal one
    //Message(Application, evCommand, cmOK, NewStr('Open file: ' + CurrentPath + Item^.FileName));
  end;
end;

procedure TFilePanel.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  if (Event.What = evKeyDown) and GetState(sfFocused) then
  begin
    case Event.KeyCode of
      kbUp:
        begin
          SetFocus(FocusedItemIndex - 1);
          ClearEvent(Event);
        end;
      kbDown:
        begin
          SetFocus(FocusedItemIndex + 1);
          ClearEvent(Event);
        end;
      kbEnter:
        begin
          ExecuteFocusedItem;
          ClearEvent(Event);
        end;
      kbCtrlPgUp, kbCtrlBack: // Ctrl+PgUp or Ctrl+Backspace for parent directory
        begin
          ChangeDirectory('..');
          ClearEvent(Event);
        end;
    end;
  end;
end;

procedure TFilePanel.DrawItem(Y: Integer; Index: Integer; IsFocused: Boolean; var B: TDrawBuffer);
var
  Color, Attrib: Byte;
  Item: PFileListItem;
  DisplayName: String;
  NameWidth: Integer;
begin
  NameWidth := Size.X;
  if NameWidth <=0 then Exit;

  // We use "((Owner <> nil) and (Owner^.Current = @Self))" focus check here
  // as GetState(sfFocused) is not reliable and may not work on app start
  if IsFocused and ((Owner <> nil) and (Owner^.Current = @Self)) then
    Color := GetColor($04) // Focused item color (palette index 3)
  else
    Color := GetColor($01); // Normal item color (palette index 1)

  MoveChar(B, ' ', Color, NameWidth); // Clear the line part

  if (FileList <> nil) and (Index < FileList^.Count) then
  begin
    Item := PFileListItem(FileList^.At(Index));
    if Item <> nil then
    begin
      DisplayName := Item^.FileName;

      if Item^.IsDirectory then
        DisplayName := '[' + DisplayName + ']';

      Attrib := Color; // File color same as normal/focused

      if Length(DisplayName) > NameWidth then
        SetLength(DisplayName, NameWidth);

      MoveStr(B, UTF8ToUTF16(DisplayName), Attrib);
    end;
  end;
  WriteLine(0, Y, NameWidth, 1, B);
end;


procedure TFilePanel.Draw;
var
  B: TDrawBuffer;
  Y, MaxDisplayItems, CurrentDisplayIndex: Integer;
begin
  inherited Draw;

  if (Size.X <= 2) or (Size.Y <= 2) then Exit;

  MaxDisplayItems := Size.Y - 2;

  for Y := 0 to MaxDisplayItems + 1 do
  begin
    CurrentDisplayIndex := TopItemIndex + Y;
    if CurrentDisplayIndex < FileList^.Count then
      DrawItem(Y, CurrentDisplayIndex, CurrentDisplayIndex = FocusedItemIndex, B)
    else // Draw empty line if no more items
    begin
      MoveChar(B, ' ', GetColor($01), Size.X);
      WriteLine(0, Y, Size.X, 1, B);
    end;
  end;
end;

end.