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

unit dnapp;

interface

uses
  dnlogger, sysutils,
  UApp, UViews, Objects, UDrivers, UMenus, // Free Vision units
  DblWnd;                                // Our double window unit

type
  PDNApp = ^TDNApp;
  TDNApp = object(TApplication)
  public
    constructor Init;
    procedure InitDeskTop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

implementation

uses commands, FVConsts; // For cmQuit, kbAltX

constructor TDNApp.Init;
begin
  inherited Init;
  // Custom application initialization can go here
end;

procedure TDNApp.InitMenuBar;
var
  R: TRect;
begin
  // For this prototype, a very minimal menu bar for Alt+X functionality
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R,
    NewMenu(
      NewSubMenu('~F~ile', hcNoContext,
        NewMenu(
          NewItem('E~x~it', 'Alt+X', kbAltX, cmQuit, hcNoContext, nil)
        ), nil
      )
    )
  ));
  if MenuBar <> nil then
    Insert(MenuBar); // Ensure it's part of the application group
end;

procedure TDNApp.InitStatusLine;
var
  R: TRect;
begin
  // For this prototype, a minimal status line
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F7~ MkDir', kbF7, cmMakeDir, // Add F7 here
      nil)),
    nil)
  ));
  if StatusLine <> nil then
    Insert(StatusLine); // Ensure it's part of the application group
end;

procedure TDNApp.InitDesktop;
var
  R: TRect;
  DW: PDoublePanelWindow;
begin
  inherited InitDesktop; // This creates Desktop: PDesktop

  Desktop^.GetExtent(R);
  // Adjust R for MenuBar and StatusLine if they are visible
  if (MenuBar <> nil) and MenuBar^.GetState(sfVisible) then
    Inc(R.A.Y);
  if (StatusLine <> nil) and StatusLine^.GetState(sfVisible) then
    Dec(R.B.Y);

  // Use all availble space, we do not need shadow here
  Dec(R.A.Y);
  Inc(R.B.Y);

  DW := New(PDoublePanelWindow, Init(R, 'DN3L Prototype - Unicode', 0));
  if DW <> nil then
    Desktop^.Insert(DW);
end;

procedure TDNApp.HandleEvent(var Event: TEvent);
begin
  // Log interesting events
  if ((Event.What = evCommand) and (Event.Command = cmQuit)) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbAltX)) or
     ((Event.What = evCommand) and (Event.Command = cmMakeDir)) or // Log F7
     ((Event.What = evKeyDown) and (Event.KeyCode = kbF7)) then   // Log F7
  begin
    Logger.Log('TDNApp.HandleEvent: Processing Event');
    Logger.Log('  What', IntToStr(Event.What));
    Logger.Log('  Command/KeyCode', Word(Event.Command)); // Use Word to log both
    Logger.Log('  InfoPtr', Event.InfoPtr);
  end;

  inherited HandleEvent(Event); // TApplication handles basic menu events etc.

  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbAltX:
        begin
          Logger.Log('TDNApp.HandleEvent: Alt+X detected, checking if Desktop can close.');
          if (Desktop = nil) or (Desktop^.Valid(cmQuit)) then
          begin
            Logger.Log('TDNApp.HandleEvent: Desktop valid for quit or nil, ending modal.');
            EndModal(cmQuit);
            ClearEvent(Event);
          end
          else
            Logger.Log('TDNApp.HandleEvent: Desktop NOT valid for quit.');
        end;
      kbF7: // Directly handle F7 if not caught by a menu
        begin
          Logger.Log('TDNApp.HandleEvent: F7 KeyDown detected. Posting cmMakeDir.');
          // Post as a command to be handled by the focused view
          Event.What := evCommand;
          Event.Command := cmMakeDir;
          Event.InfoPtr := nil;
          PutEvent(Event); // Put it back in the queue for focused view processing
          // Don't ClearEvent here, let the focused view handle it.
        end;
    end;
  end
  else if Event.What = evCommand then
  begin
    case Event.Command of
      cmMakeDir: // If it bubbles up to the application, pass to Desktop
        begin
          Logger.Log('TDNApp.HandleEvent: cmMakeDir command received at App level. Passing to Desktop.');
          if Desktop <> nil then
            Desktop^.HandleEvent(Event);
          // If Desktop doesn't clear it, it's unhandled at this level
        end;
    end;
  end;
end;

end.