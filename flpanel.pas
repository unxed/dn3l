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

{$LONGSTRINGS ON}

unit flpanel;

interface

uses
  UViews, Objects, UDrivers, UDialogs,
  // Dos, // No longer strictly needed here if SysUtils covers FindFirst/Next
  SysUtils, // For FindFirst, FindNext, DirectoryExists etc.
  DNLogger,
  commands,
  UFVCommon;

type
  PFileListItem = ^TFileListItem;
  TFileListItem = object(TObject)
    FileName: UnicodeString;
    IsDirectory: Boolean;
    // Add other attributes if needed later, e.g., Size, DateTime
    // DateTime: TDateTime;
    // Size: Int64;
    constructor Init(const AFileName: UnicodeString; AIsDirectory: Boolean);
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
    CurrentPath: UnicodeString;
    FocusedItemIndex: Integer;
    TopItemIndex: Integer;

    constructor Init(var Bounds: TRect);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure LoadDirectory(const Path: UnicodeString);
    procedure SetFocus(NewFocusIndex: Integer);
    procedure MakeDirectoryDialog;
  private
    procedure DrawItem(Y: Integer; Index: Integer; IsFocused: Boolean; var B: TDrawBuffer);
    procedure ChangeDirectory(const NewPath: UnicodeString);
    procedure ExecuteFocusedItem;
  end;

implementation

uses
  FVConsts,
  UApp,
  UMsgBox;//,
//  UStdDlg; // Keep for InputBox and MessageBox

{ TFileListItem }
// ... (implementation as before) ...
constructor TFileListItem.Init(const AFileName: UnicodeString; AIsDirectory: Boolean);
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
  inherited Init(20, 10);
end;


{ TFilePanel }

constructor TFilePanel.Init(var Bounds: TRect);
var
  InitialPath: UnicodeString;
begin
  Logger.Log('  TFilePanel.Init starting...');
  Logger.Log('  Initial Bounds for TFilePanel', Bounds);

  inherited Init(Bounds);
  Options := Options or ofFramed or ofSelectable or ofBuffered or ofFirstClick;
  GrowMode := gfGrowAll;
  EventMask := EventMask or evKeyDown or evCommand;

  FileList := New(PFileListCollection, Init);
  FocusedItemIndex := 0;
  TopItemIndex := 0;

  InitialPath := SysUtils.GetCurrentDir; // Using SysUtils for more robust current dir
  CurrentPath := IncludeTrailingPathDelimiter(InitialPath);
  Logger.Log('  TFilePanel.Init: Initial CurrentPath before LoadDirectory', CurrentPath);
  LoadDirectory(CurrentPath);

  Logger.Log('  TFilePanel.Init finished. Options', Options);
end;

destructor TFilePanel.Done;
// ... (as before) ...
begin
  Logger.Log('  TFilePanel.Done starting for panel at', Origin);
  if Assigned(FileList) then
    Dispose(FileList);
  inherited Done;
  Logger.Log('  TFilePanel.Done finished for panel at', Origin);
end;


procedure TFilePanel.LoadDirectory(const Path: UnicodeString);
var
  SR: TSearchRec; // SysUtils.TSearchRec
  Item: PFileListItem;
  DirToList: UnicodeString;
  TempPath: UnicodeString;
  IsRoot: Boolean;
  OldFocusedName: UnicodeString;
  I: Integer;
  // DError: Word; // SysUtils.FindFirst/Next don't use DosError in the same way
  FindResult: Integer;
  FileCount: LongInt;
begin
  TempPath := ExpandFileName(Path);
  TempPath := IncludeTrailingPathDelimiter(TempPath);
  Logger.Log('  TFilePanel.LoadDirectory: PROCEDURE ENTRY. Attempting to load path', TempPath);

  OldFocusedName := '';
  if Assigned(FileList) and (FileList^.Count > 0) and
     (FocusedItemIndex >= 0) and (FocusedItemIndex < FileList^.Count) then
  begin
    Item := PFileListItem(FileList^.At(FocusedItemIndex));
    if Item <> nil then OldFocusedName := Item^.FileName;
    Logger.Log('  TFilePanel.LoadDirectory: Preserving OldFocusedName', OldFocusedName);
  end;

  Logger.Log('  TFilePanel.LoadDirectory: Calling DirectoryExists for', TempPath);
  if not DirectoryExists(TempPath) then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: Path does not exist or is not a directory', TempPath);
    if Assigned(FileList) then FileList^.FreeAll;
    if FileList = nil then FileList := New(PFileListCollection, Init);
    Item := New(PFileListItem, Init('<Path not found: ' + TempPath + '>', False));
    FileList^.Insert(Item);
    CurrentPath := TempPath;
    FocusedItemIndex := 0;
    TopItemIndex := 0;
    if GetState(sfVisible) then DrawView;
    Logger.Log('  TFilePanel.LoadDirectory: Exiting due to non-existent path.');
    Exit;
  end;
  Logger.Log('  TFilePanel.LoadDirectory: DirectoryExists check passed for', TempPath);

  if Assigned(FileList) then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: Freeing existing FileList items.');
    FileList^.FreeAll;
  end
  else
  begin
    Logger.Log('  TFilePanel.LoadDirectory: Creating new FileList collection.');
    FileList := New(PFileListCollection, Init);
  end;

  CurrentPath := TempPath;
  DirToList := CurrentPath + '*'; // SysUtils.FindFirst typically uses '*' for all
                                  // On Windows, FindFirst will handle '*.*' from '*' if needed.

  IsRoot := False;
  if CurrentPath = PathDelim then IsRoot := True
  else if (Length(CurrentPath) = 3) and (CurrentPath[2] = ':') and (CurrentPath[3] = PathDelim) then IsRoot := True;

  Logger.Log('  TFilePanel.LoadDirectory: IsRoot', IsRoot);
  Logger.Log('  TFilePanel.LoadDirectory: DirToList for SysUtils.FindFirst', DirToList);

  if not IsRoot then
  begin
    Item := New(PFileListItem, Init('..', True));
    FileList^.Insert(Item);
    Logger.Log('  TFilePanel.LoadDirectory: Added ".." entry.');
  end;

  FileCount := 0;
  Logger.Log('  TFilePanel.LoadDirectory: Calling SysUtils.FindFirst with DirToList:', DirToList);
  FindResult := SysUtils.FindFirst(DirToList, faAnyFile, SR); // Using SysUtils.FindFirst

  if FindResult <> 0 then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: SysUtils.FindFirst failed for path', DirToList + ' FindResult: ' + IntToStr(FindResult));
    Item := New(PFileListItem, Init('<Error ' + IntToStr(FindResult) + ' reading: ' + CurrentPath + '>', False));
    if FileList=nil then FileList := New(PFileListCollection, Init);
    FileList^.Insert(Item);
  end else
  begin
    Logger.Log('  TFilePanel.LoadDirectory: SysUtils.FindFirst successful. Processing entries...');
    repeat
      Inc(FileCount);
      // Logger.Log('  Loop Iteration', FileCount); // Can be too verbose
      // Logger.Log('    SR.Name', SR.Name);
      // Logger.Log('    SR.Attr (Hex)', IntToHex(SR.Attr, 2));

      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        Item := New(PFileListItem, Init(SR.Name, (SR.Attr and faDirectory) <> 0));
        // You might want to store SR.Time and SR.Size in TFileListItem here
        // Item.DateTime := SR.Time;
        // Item.Size := SR.Size;
        FileList^.Insert(Item);
      end;
      FindResult := SysUtils.FindNext(SR);
    until FindResult <> 0;

    SysUtils.FindClose(SR);
    Logger.Log('  TFilePanel.LoadDirectory: SysUtils.FindFirst/FindNext loop completed. Total entries found:', FileCount);
  end;

  FocusedItemIndex := -1;
  if OldFocusedName <> '' then
  begin
    for I := 0 to FileList^.Count - 1 do
    begin
      if PFileListItem(FileList^.At(I))^.FileName = OldFocusedName then
      begin
        FocusedItemIndex := I;
        break;
      end;
    end;
  end;

  if FocusedItemIndex = -1 then
  begin
    if FileList^.Count > 0 then
    begin
       if (not IsRoot) and (PFileListItem(FileList^.At(0))^.FileName = '..') then
          FocusedItemIndex := 0
       else
          FocusedItemIndex := 0;
    end else
        FocusedItemIndex := 0;
  end;

  TopItemIndex := 0;
  if Size.Y - 2 > 0 then
  begin
    if FocusedItemIndex >= (Size.Y - 2) then
        TopItemIndex := FocusedItemIndex - (Size.Y - 2) + 1;
  end;
  if TopItemIndex < 0 then TopItemIndex := 0;

  Logger.Log('  TFilePanel.LoadDirectory: Final FileList^.Count', FileList^.Count);
  Logger.Log('  TFilePanel.LoadDirectory: Final FocusedItemIndex', FocusedItemIndex);
  Logger.Log('  TFilePanel.LoadDirectory: Final TopItemIndex', TopItemIndex);

  if GetState(sfVisible) then
  begin
    Logger.Log('  TFilePanel.LoadDirectory: Panel is visible, calling DrawView.');
    DrawView;
  end
  else
    Logger.Log('  TFilePanel.LoadDirectory: Panel not visible, DrawView skipped. State:', State);
  Logger.Log('  TFilePanel.LoadDirectory: PROCEDURE EXIT.');
end;

// ... (SetFocus, ChangeDirectory, ExecuteFocusedItem, MakeDirectoryDialog, HandleEvent, DrawItem, Draw) ...
// ... (These methods should largely remain the same as they operate on FileList) ...
procedure TFilePanel.SetFocus(NewFocusIndex: Integer);
var
  MaxItemsVisible: Integer;
begin
  if (FileList = nil) or (FileList^.Count = 0) then
  begin
    FocusedItemIndex := 0;
    TopItemIndex := 0;
    if GetState(sfVisible) then DrawView;
    Exit;
  end;

  if NewFocusIndex < 0 then
    FocusedItemIndex := 0
  else if NewFocusIndex >= FileList^.Count then
    FocusedItemIndex := FileList^.Count - 1
  else
    FocusedItemIndex := NewFocusIndex;

  MaxItemsVisible := Size.Y;
  if MaxItemsVisible <= 0 then MaxItemsVisible := 1;

  if FocusedItemIndex < TopItemIndex then
    TopItemIndex := FocusedItemIndex;
  if FocusedItemIndex >= TopItemIndex + MaxItemsVisible then
    TopItemIndex := FocusedItemIndex - MaxItemsVisible + 1;

  if TopItemIndex < 0 then TopItemIndex := 0;

  if FileList^.Count > 0 then
  begin
    if TopItemIndex > FileList^.Count - MaxItemsVisible then
        TopItemIndex := FileList^.Count - MaxItemsVisible;
  end else
  begin
    TopItemIndex := 0;
  end;
  if TopItemIndex < 0 then TopItemIndex := 0;

  if GetState(sfVisible) then DrawView;
end;

procedure TFilePanel.ChangeDirectory(const NewPath: UnicodeString);
var
  FocusName: UnicodeString;
  IsCurrentPathRoot: Boolean;
  I: Integer;
begin
  FocusName := '';

  if NewPath = '..' then
  begin
    IsCurrentPathRoot := False;
    if CurrentPath = PathDelim then IsCurrentPathRoot := True
    else if (Length(CurrentPath) = 3) and (CurrentPath[2] = ':') and (CurrentPath[3] = PathDelim) then IsCurrentPathRoot := True;

    if not IsCurrentPathRoot then
    begin
      FocusName := SysUtils.ExtractFileName(ExcludeTrailingPathDelimiter(CurrentPath));
      LoadDirectory(SysUtils.ExtractFilePath(ExcludeTrailingPathDelimiter(CurrentPath)));
    end else
    begin
        Logger.Log('  TFilePanel.ChangeDirectory: Already at root, ".." does nothing.');
    end;
  end else
  begin
    LoadDirectory(NewPath);
  end;

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
  SetFocus(0);
end;

procedure TFilePanel.ExecuteFocusedItem;
var
  Item: PFileListItem;
  NewPath: UnicodeString;
  MsgToLog: UnicodeString;
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
      NewPath := CurrentPath + Item^.FileName;
      ChangeDirectory(NewPath);
    end;
  end
  else
  begin
    MsgToLog := 'Open file: ' + CurrentPath + Item^.FileName;
    Logger.Log('  TFilePanel.ExecuteFocusedItem: Attempting to "open" file', Item^.FileName);
    if UApp.Application <> nil then
        Message(UApp.Application, evCommand, cmOK, NewStr(MsgToLog));
  end;
end;

procedure TFilePanel.MakeDirectoryDialog;
var
  NewDirName: UnicodeString;
  NewDirNameSw : Sw_String;
  DlgTitleSw, DlgPromptSw: Sw_String;
  Res: Word;
  FullNewPath: UnicodeString;
  IOStatus: Integer;
  I: Integer;
begin
  Logger.Log('  TFilePanel.MakeDirectoryDialog called.');
  if not GetState(sfFocused) then
  begin
    Logger.Log('  TFilePanel.MakeDirectoryDialog: Panel not focused. Aborting.');
    Exit;
  end;

  NewDirName := '';
  NewDirNameSw := '';

  DlgTitleSw := 'Make Directory';
  DlgPromptSw := 'New directory name:';

  NewDirNameSw := UnicodeString(NewDirName);

  Res := InputBox(DlgTitleSw, DlgPromptSw, NewDirNameSw, 255);

  NewDirName := string(NewDirNameSw);

  if Res = cmOK then
  begin
    Trim(NewDirName);
    Logger.Log('  TFilePanel.MakeDirectoryDialog: User entered', NewDirName);
    if NewDirName = '' then
    begin
      Logger.Log('  TFilePanel.MakeDirectoryDialog: Empty name, aborting.');
      Exit;
    end;

    if (Pos(PathDelim, NewDirName) > 0) or (Pos(':', NewDirName) > 0) or
       (Pos('*', NewDirName) > 0) or (Pos('?', NewDirName) > 0) then
    begin
      UMsgBox.MessageBox('Invalid directory name: contains illegal characters.', nil, mfError or mfOKButton);
      Logger.Log('  TFilePanel.MakeDirectoryDialog: Invalid characters in name.');
      Exit;
    end;

    FullNewPath := CurrentPath + NewDirName;
    Logger.Log('  TFilePanel.MakeDirectoryDialog: Attempting to create', FullNewPath);

    {$I-}
    System.MkDir(FullNewPath);
    IOStatus := System.IOResult;
    {$I+}
    if IOStatus = 0 then
    begin
      Logger.Log('  TFilePanel.MakeDirectoryDialog: Directory created successfully.');
      LoadDirectory(CurrentPath);
      for I := 0 to FileList^.Count - 1 do
      begin
        if PFileListItem(FileList^.At(I))^.FileName = NewDirName then
        begin
          SetFocus(I);
          break;
        end;
      end;
    end
    else
    begin
      UMsgBox.MessageBox('Error creating directory: ' + NewDirName + ' (Error ' + IntToStr(IOStatus) + ')',
                         nil, mfError or mfOKButton);
      Logger.Log('  TFilePanel.MakeDirectoryDialog: MkDir failed. IOResult', IOStatus);
    end;
  end
  else
    Logger.Log('  TFilePanel.MakeDirectoryDialog: Dialog cancelled by user.');
end;

procedure TFilePanel.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  if GetState(sfFocused) then
  begin
    if (Event.What = evKeyDown) then
    begin
      case Event.KeyCode of
        kbCtrlEnter:
          begin
            MessageBox('Ctrl+Enter pressed', nil, mfOKButton );
          end;
        kbUp:
          begin
            Logger.Log('  TFilePanel.HandleEvent: kbUp on focused panel', Origin);
            SetFocus(FocusedItemIndex - 1);
            ClearEvent(Event);
          end;
        kbDown:
          begin
            Logger.Log('  TFilePanel.HandleEvent: kbDown on focused panel', Origin);
            SetFocus(FocusedItemIndex + 1);
            ClearEvent(Event);
          end;
        kbEnter:
          begin
            Logger.Log('  TFilePanel.HandleEvent: kbEnter on focused panel', Origin);
            ExecuteFocusedItem;
            ClearEvent(Event);
          end;
        kbCtrlPgUp, kbCtrlBack:
          begin
            Logger.Log('  TFilePanel.HandleEvent: kbCtrlPgUp/CtrlBack on focused panel', Origin);
            ChangeDirectory('..');
            ClearEvent(Event);
          end;
      end;
    end
    else if (Event.What = evCommand) then
    begin
      case Event.Command of
        cmMakeDir:
          begin
            Logger.Log('  TFilePanel.HandleEvent: cmMakeDir received by focused panel.');
            MakeDirectoryDialog;
            ClearEvent(Event);
          end;
      end;
    end;
{  end
  else
  begin
      if (Event.What = evKeyDown) and (Event.KeyCode in [kbUp, kbDown, kbEnter, kbCtrlPgUp, kbCtrlBack, kbF7]) then
          Logger.Log('  TFilePanel.HandleEvent: Key event for nav/F7 received but panel NOT FOCUSED, ignoring. KeyCode:', Event.KeyCode)
      else if (Event.What = evCommand) and (Event.Command = cmMakeDir) then
          Logger.Log('  TFilePanel.HandleEvent: cmMakeDir received but panel NOT FOCUSED, ignoring.', Origin);
}  end;
end;

procedure TFilePanel.DrawItem(Y: Integer; Index: Integer; IsFocused: Boolean; var B: TDrawBuffer);
var
  ItemColor, DirColor, FocusColor, FocusDirColor, Attrib: Byte;
  Item: PFileListItem;
  DisplayName: UnicodeString;
  NameWidth: Integer;
begin
  NameWidth := Size.X;
  if NameWidth <=0 then Exit;

  ItemColor     := GetColor($01);
  DirColor      := GetColor($02);
  FocusColor    := GetColor($04);
  FocusDirColor := GetColor($04);

  if IsFocused and GetState(sfFocused) then
    Attrib := FocusColor
  else
    Attrib := ItemColor;

  MoveChar(B, ' ', Attrib, NameWidth);

  if (FileList <> nil) and (Index >= 0) and (Index < FileList^.Count) then
  begin
    Item := PFileListItem(FileList^.At(Index));
    if Item <> nil then
    begin
      DisplayName := Item^.FileName;
      if Item^.IsDirectory then
      begin
        if IsFocused and GetState(sfFocused) then
            Attrib := FocusDirColor
        else
            Attrib := DirColor;
        DisplayName := '[' + DisplayName + ']';
      end
      else
      begin
        if IsFocused and GetState(sfFocused) then
            Attrib := FocusColor
        else
            Attrib := ItemColor;
      end;

      if UDrivers.StrWidth(DisplayName) > NameWidth then
      begin
        while (UDrivers.StrWidth(DisplayName) > NameWidth) and (Length(DisplayName) > 0) do
            SetLength(DisplayName, Length(DisplayName) - 1);
      end;

      MoveStr(B, DisplayName, Attrib);
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

  MaxDisplayItems := Size.Y;

  for Y := 0 to MaxDisplayItems - 1 do
  begin
    CurrentDisplayIndex := TopItemIndex + Y;
    if (FileList <> nil) and (CurrentDisplayIndex >=0) and (CurrentDisplayIndex < FileList^.Count) then
      DrawItem(Y, CurrentDisplayIndex, CurrentDisplayIndex = FocusedItemIndex, B)
    else
    begin
      MoveChar(B, ' ', GetColor($01), Size.X);
      WriteLine(0, Y, Size.X, 1, B);
    end;
  end;
end;

end.