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

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  UViews, Objects, UDrivers,
  DNLogger;

type
  PFilePanel = ^TFilePanel;
  TFilePanel = object(TGroup)
  public
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual; // Added Draw method
  end;

implementation

constructor TFilePanel.Init(var Bounds: TRect);
begin
  Logger.Log('  TFilePanel.Init starting...');
  Logger.Log('  Initial Bounds for TFilePanel', Bounds);

  inherited Init(Bounds);
  Options := Options or ofFramed or ofSelectable;
  GrowMode := gfGrowAll;

  Logger.Log('  TFilePanel.Init finished. Options', Options);
  Logger.Log('  TFilePanel Size after TGroup.Init', Self.Size);
  Logger.Log('  TFilePanel Origin after TGroup.Init', Self.Origin);

  if (Bounds.A.X >= Bounds.B.X) or (Bounds.A.Y >= Bounds.B.Y) then
     Logger.Log('  WARNING: TFilePanel initialized with zero or negative size!')
  else
     Logger.Log('  TFilePanel initialized with valid size.');
end;

procedure TFilePanel.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  PanelID: string;
begin
  Logger.Log('  TFilePanel.Draw CALLED for panel at', Self.Origin);
  Logger.Log('  TFilePanel.Draw: Size', Self.Size);
  Logger.Log('  TFilePanel.Draw: State (Hex)', Self.State);
  Logger.Log('  TFilePanel.Draw: Options (Hex)', Self.Options);
  Logger.Log('  TFilePanel.Draw: sfVisible set?', GetState(sfVisible));
  Logger.Log('  TFilePanel.Draw: ofFramed set?', Options and ofFramed <> 0);

  // Call inherited Draw first to draw the frame if ofFramed is set
  // and to handle background if not buffered or if options specify.
  inherited Draw;
  Logger.Log('  TFilePanel.Draw: inherited Draw completed.');

  // Now draw something inside the client area of the panel if it's large enough
  // The client area is Size.X-2, Size.Y-2 because of the frame.
  if (Size.X > 2) and (Size.Y > 2) then
  begin
    Color := GetColor($01); // GetColor(1) for TGroup typically gives normal text color

    // Simple identifier for which panel this is (based on its X origin)
    if Origin.X < Owner^.Size.X div 2 then
      PanelID := 'Left Panel'
    else
      PanelID := 'Right Panel';

    // Draw the PanelID string inside the panel's client area
    // Coordinates for WriteLine are relative to the TFilePanel's client area.
    // The client area for a framed group starts at (1,1) relative to its own Origin.
    // So to draw at the top-left corner *inside* the frame, use (0,0) for WriteLine
    // if TGroup's WriteLine handles client coordinates, or (1,1) if it expects
    // absolute coordinates within the view's bounds.
    // Let's assume WriteLine (and WriteStr below) work with coordinates
    // relative to the view's full bounds (0,0) to (Size.X-1, Size.Y-1).
    // The frame itself occupies row/col 0 and Size.Y-1 / Size.X-1.
    // So, client area starts at (1,1).

    // Clear a line inside the panel for our text
    MoveChar(B, ' ', Color, Size.X - 2); // Width of client area
    WriteLine(1, 1, Size.X - 2, 1, B); // Draw at (1,1) within the panel

    // Write the text
    if Length(PanelID) <= (Size.X - 2) then
    begin
        Logger.Log('  TFilePanel.Draw: Drawing PanelID', PanelID);
        // WriteStr expects coordinates relative to the view's origin (0,0)
        WriteStr(2, 1, PanelID, Color);
    end
    else
        Logger.Log('  TFilePanel.Draw: PanelID too long for panel width', PanelID);

    // You could draw a border for the client area too for more debugging
    // GetClientRect(R); -- TGroup does not have GetClientRect
    // Instead use Size.X-2, Size.Y-2
    // For Y := 0 to Size.Y - 3 do
    // begin
    //   MoveChar(B, '#', Color, Size.X-2);
    //   WriteLine(1, 1 + Y, Size.X - 2, 1, B);
    // end;

  end
  else
  begin
    Logger.Log('  TFilePanel.Draw: Panel too small to draw content (Size.X <= 2 or Size.Y <= 2).');
  end;
  Logger.Log('  TFilePanel.Draw finished for panel at', Self.Origin);
end;

end.