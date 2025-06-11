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

unit dblwnd;

interface

uses
  UViews, Objects, UDrivers,
  FlPanel,
  DNLogger;

type
  PDoublePanelWindow = ^TDoublePanelWindow;
  TDoublePanelWindow = object(TWindow)
  public
    LeftPanel: PFilePanel;
    RightPanel: PFilePanel;
    constructor Init(var Bounds: TRect; ATitle: String; ANumber: Word);
  end;

implementation

constructor TDoublePanelWindow.Init(var Bounds: TRect; ATitle: String; ANumber: Word);
var
  ClientR, PanelR: TRect;
  MidX: Integer;
begin
  Logger.Log('--------------------------------------------------');
  Logger.Log('TDoublePanelWindow.Init starting...');
  Logger.Log('Initial Bounds for TDoublePanelWindow', Bounds);
  Logger.Log('Title', ATitle);
  Logger.Log('Window Number', ANumber);

  inherited Init(Bounds, ATitle, ANumber);
  Flags := Flags or wfGrow;
  Logger.Log('TDoublePanelWindow.Init: inherited TWindow.Init completed.');
  Logger.Log('TDoublePanelWindow Size after TWindow.Init', Self.Size);
  Logger.Log('TDoublePanelWindow Origin after TWindow.Init', Self.Origin);

  GetExtent(ClientR);
  Logger.Log('TDoublePanelWindow ClientRect (ClientR)', ClientR);

  if (ClientR.B.X <= ClientR.A.X) or (ClientR.B.Y <= ClientR.A.Y) then
  begin
    Logger.Log('WARNING: TDoublePanelWindow ClientRect has zero or negative size!', ClientR);
    // Panels will likely not be visible or correctly sized.
  end;

  MidX := (ClientR.A.X + ClientR.B.X) div 2; // More robust for ClientR.A.X potentially not 0
  Logger.Log('MidX calculated', MidX);

  // Left Panel
  PanelR.A.X := ClientR.A.X + 1;
  PanelR.A.Y := ClientR.A.Y + 1;
  PanelR.B.X := MidX - 1;
  PanelR.B.Y := ClientR.B.Y - 1;
  Logger.Log('Calculated Bounds for LeftPanel (PanelR)', PanelR);
  LeftPanel := New(PFilePanel, Init(PanelR));
  if LeftPanel <> nil then
  begin
    Logger.Log('LeftPanel object created', LeftPanel);
    Insert(LeftPanel);
    Logger.Log('LeftPanel inserted into TDoublePanelWindow.');
  end
  else
    Logger.Log('LeftPanel FAILED to create.');

  // Right Panel
  PanelR.A.X := MidX;
  PanelR.A.Y := ClientR.A.Y + 1;
  PanelR.B.X := ClientR.B.X - 1;
  PanelR.B.Y := ClientR.B.Y - 1;
  Logger.Log('Calculated Bounds for RightPanel (PanelR)', PanelR);
  RightPanel := New(PFilePanel, Init(PanelR));
  if RightPanel <> nil then
  begin
    Logger.Log('RightPanel object created', RightPanel);
    Insert(RightPanel);
    Logger.Log('RightPanel inserted into TDoublePanelWindow.');
  end
  else
    Logger.Log('RightPanel FAILED to create.');

  Logger.Log('TDoublePanelWindow.Init finished.');
  Logger.Log('--------------------------------------------------');
end;

end.