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

{$mode objfpc}{$H+} // Or {$mode tp} if you want stricter TP compatibility for syntax
{$codepage UTF8}

interface

uses
  UViews, Objects, UDrivers, UDialogs, // Free Vision units
  Dos,       // For FindFirst, FindNext, SearchRec, fSplit, GetCurDir
  SysUtils,  // For DirectoryExists, ExtractFileName, ExtractFilePath (modern helpers)
  DNLogger;

type
  PFileListItem = ^TFileListItem;
  TFileListItem = object(TObject) // Simple object to hold file name
    FileName: String; // Using FPC's default string (Ansi/UTF8)
    IsDirectory: Boolean;
    constructor Init(const AFileName: String; AIsDirectory: Boolean);
    destructor Done; virtual;
  end;

  PFileListCollection = ^TFileListCollection;
  TFileListCollection = object(TCollection)
    constructor Init;
    // We might add sorting methods later
  end;

  PFilePanel = ^TFilePanel;
  TFilePanel = object(TGroup)
  public
    FileList: PFileListCollection;
    CurrentPath: String; // Store the current path
    constructor Init(var Bounds: TRect);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure LoadDirectory(const Path: String);
    // function GetPalette: PPalette; virtual; // Skip for now
  end;

implementation

{ TFileListItem }

constructor TFileListItem.Init(const AFileName: String; AIsDirectory: Boolean);
begin
  inherited Init;
  FileName := AFileName;
  IsDirectory := AIsDirectory;
end;

destructor TFileListItem.Done;
begin
  // FileName string is managed automatically
  inherited Done;
end;

{ TFileListCollection }

constructor TFileListCollection.Init;
begin
  // Base TCollection Init is suitable for now.
  // Parameters are: initial size, delta for growth.
  inherited Init(10, 5);
end;

{ TFilePanel }

constructor TFilePanel.Init(var Bounds: TRect);
var
  InitialPath: String; // DOS unit PathStr for GetCurDir
begin
  Logger.Log('  TFilePanel.Init starting...');
  Logger.Log('  Initial Bounds for TFilePanel', Bounds);

  inherited Init(Bounds);
  Options := Options or ofFramed or ofSelectable or ofBuffered; // Added ofBuffered
  GrowMode := gfGrowAll;

  FileList := New(PFileListCollection, Init);

  {$I-}
  GetDir(0, InitialPath); // Get current directory for drive 0 (current drive)
  {$I+}
  if IOResult <> 0 then
    CurrentPath := '.' + DirectorySeparator // Default to current dir on error
  else
    CurrentPath := IncludeTrailingPathDelimiter(InitialPath);

  LoadDirectory(CurrentPath);

  Logger.Log('  TFilePanel.Init finished. Options', Options);
  Logger.Log('  TFilePanel Size after TGroup.Init', Self.Size);
  Logger.Log('  TFilePanel Origin after TGroup.Init', Self.Origin);

  if (Bounds.A.X >= Bounds.B.X) or (Bounds.A.Y >= Bounds.B.Y) then
     Logger.Log('  WARNING: TFilePanel initialized with zero or negative size!')
  else
     Logger.Log('  TFilePanel initialized with valid size.');
end;

destructor TFilePanel.Done;
begin
  Logger.Log('  TFilePanel.Done starting for panel at', Origin);
  if Assigned(FileList) then
    FreeAndNil(FileList); // FreeVision's way to dispose and nil a TCollection
  inherited Done;
  Logger.Log('  TFilePanel.Done finished for panel at', Origin);
end;

procedure TFilePanel.LoadDirectory(const Path: String);
var
  SR: TRawbyteSearchRec;
  Item: PFileListItem;
  DirToList: String;
begin
  Logger.Log('  TFilePanel.LoadDirectory: Loading path', Path);
  if Assigned(FileList) then
    FileList^.FreeAll // Clear existing items
  else
    FileList := New(PFileListCollection, Init);

  CurrentPath := IncludeTrailingPathDelimiter(Path);
  DirToList := CurrentPath + '*.*'; // Or just '*' on Unix

  // Add ".." for parent directory, unless it's a root
  if (Length(CurrentPath) > 0) and
     not ((Length(CurrentPath) = 1) and (CurrentPath[1] = DirectorySeparator)) and // Not root "/"
     not ((Length(CurrentPath) = 3) and (CurrentPath[2] = ':') and (CurrentPath[3] = DirectorySeparator)) then // Not "C:\"
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
    // Optionally insert an error message item
    Item := New(PFileListItem, Init('<Error reading directory>', False));
    FileList^.Insert(Item);
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
  Logger.Log('  TFilePanel.LoadDirectory: Found items', FileList^.Count);
end;

procedure TFilePanel.Draw;
var
  B: TDrawBuffer;
  Color, Attrib: Byte;
  PanelIDText: String; // Changed from UnicodeString
  I, Y, MaxDisplayItems, NameWidth: Integer;
  Item: PFileListItem;
  DisplayName: String;
begin
  // Logger.Log('  TFilePanel.Draw CALLED for panel at', Self.Origin);
  // Logger.Log('  TFilePanel.Draw: Size', Self.Size);

  inherited Draw; // This draws the frame and clears the background

  if (Size.X <= 2) or (Size.Y <= 2) then
  begin
    // Logger.Log('  TFilePanel.Draw: Panel too small for content.');
    Exit;
  end;

  // Client area is inside the frame
  MaxDisplayItems := Size.Y - 2;
  NameWidth := Size.X - 2; // Width available for file name inside the frame

  if NameWidth <=0 then Exit;

  Color := GetColor($01); // Normal text color

  for Y := 0 to MaxDisplayItems - 1 do
  begin
    MoveChar(B, ' ', Color, NameWidth); // Clear the line inside the panel

    if (FileList <> nil) and (Y < FileList^.Count) then
    begin
      Item := PFileListItem(FileList^.At(Y));
      if Item <> nil then
      begin
        DisplayName := Item^.FileName;
        if Item^.IsDirectory then
        begin
          Attrib := GetColor($02); // Example: different color for directories (use palette index)
          // You might want to prefix/suffix directories, e.g., "[DIR]" or "/"
          DisplayName := '[' + DisplayName + ']';
        end
        else
          Attrib := Color;

        // Truncate if too long
        if Length(DisplayName) > NameWidth then
          SetLength(DisplayName, NameWidth);

        MoveStr(B, DisplayName, Attrib);
      end;
    end;
    // WriteLine coordinates are relative to the view's (0,0)
    // Frame takes up row 0 and row Size.Y-1.
    // Client area Y starts at 1.
    WriteLine(1, Y + 1, NameWidth, 1, B);
  end;
  // Logger.Log('  TFilePanel.Draw finished for panel at', Self.Origin);
end;

end.