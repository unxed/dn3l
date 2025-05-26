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

unit dnlogger;

{$mode objfpc}{$H+}

interface

uses
  Classes,   // For TObject and Exception (if used for more advanced logging)
  Objects;  // From Free Vision for TRect, TPoint, and base TObject (PObject)

type
  TLogger = class
  private
    FLogFile: Text;
    FInitialized: Boolean;
    FLogFilePath: string;
    FOpenFileError: Boolean;
    procedure OpenLogFile;
    function GetTimestamp: string;
  public
    constructor Create(const ALogFilePath: string = 'dn3l.log');
    destructor Destroy; override;

    procedure Log(const Message: string); overload; // Ansi/UTF8 String
    procedure Log(const Key: string; const Value: UnicodeString); overload;
    procedure Log(const Key: string; const Value: string); overload; // Ansi/UTF8 String
    procedure Log(const Key: string; const Value: ShortString); overload; // Explicit ShortString
    //procedure Log(const Key: string; const Value: Integer); overload;
    procedure Log(const Key: string; const Value: Word); overload;
    procedure Log(const Key: string; const Value: LongInt); overload;
    procedure Log(const Key: string; const Value: Boolean); overload;
    procedure Log(const Key: string; const Value: Pointer); overload;
    procedure Log(const Key: string; const R: TRect); overload;
    procedure Log(const Key: string; const P: TPoint); overload;
  end;

var
  Logger: TLogger;

implementation

uses
  {$IFDEF UNIX}
  Unix, // For gettimeofday on Unix-like for milliseconds
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows, // For GetLocalTime on Windows for milliseconds
  {$ENDIF}
  SysUtils, // For FormatDateTime and general string/conversion utils
  Dos,      // For GetDate, GetTime
  UDrivers; // For TRect/TPoint if UObjects doesn't bring them (it should)

{ TLogger }

constructor TLogger.Create(const ALogFilePath: string);
begin
  inherited Create;
  FInitialized := False;
  FLogFilePath := ALogFilePath;
  FOpenFileError := False;
  OpenLogFile;
  if FInitialized then
     Writeln(FLogFile, GetTimestamp + ': Logger initialized. Log file: ' + FLogFilePath);
end;

destructor TLogger.Destroy;
begin
  if FInitialized then
  begin
    Log('Logger finalizing.');
    Close(FLogFile);
    FInitialized := False;
  end;
  inherited Destroy;
end;

function TLogger.GetTimestamp: string;
var
  Y, M, D, H, Min, S, MS, WD: Word; // WD for DayOfWeek if needed by GetDate
  {$IFDEF UNIX}
  tv: TTimeVal;
  {$ENDIF}
  {$IFDEF WINDOWS}
  st: TSystemTime;
  {$ENDIF}
begin
  {$IFDEF FPC_DOTTEDUNITS} // Or a more specific check for modern FPC versions
  // This branch assumes SysUtils.Now and DecodeDateTime are preferred and available
  // and that 'Now' gives sufficient precision or SysUtils handles underlying OS calls.
  try
    DecodeDateTime(SysUtils.Now, Y, M, D, H, Min, S, MS);
  except
    // Fallback if DecodeDateTime or Now causes issues (e.g. minimal SysUtils)
    Dos.GetDate(Y, M, D, WD);
    Dos.GetTime(H, Min, S, MS);
    MS := MS * 10; // Convert 1/100th sec to milliseconds
  end;
  {$ELSE}
  // Classic DOS unit calls
  Dos.GetDate(Y, M, D, WD);
  Dos.GetTime(H, Min, S, MS);
  MS := MS * 10; // Convert 1/100th sec to milliseconds
  {$ENDIF}

  // Attempt to get more precise milliseconds if possible, overwriting MS from GetTime
  {$IFDEF UNIX}
  if fpGetTimeOfDay(@tv, nil) = 0 then
    MS := tv.tv_usec div 1000;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows.GetLocalTime(st); // st is TSystemTime from Windows unit
  Y := st.wYear; M := st.wMonth; D := st.wDay;
  H := st.wHour; Min := st.wMinute; S := st.wSecond;
  MS := st.wMilliseconds;
  {$ENDIF}

  Result := SysUtils.Format('%.4d-%.2d-%.2d %.2d:%.2d:%.2d.%.3d', [Y, M, D, H, Min, S, MS]);
end;

procedure TLogger.OpenLogFile;
begin
  if FInitialized or FOpenFileError then Exit;

  Assign(FLogFile, FLogFilePath);
  {$I-}
  Append(FLogFile);
  {$I+}
  if IOResult <> 0 then
  begin
    {$I-}
    Rewrite(FLogFile);
    {$I+}
    if IOResult <> 0 then
    begin
      System.WriteLn(StdErr, 'Error: Could not open log file: ' + FLogFilePath + '. IOResult: ' + IntToStr(IOResult));
      FOpenFileError := True;
      Exit;
    end;
  end;
  FInitialized := True;
end;

procedure TLogger.Log(const Message: string);
begin
  if not FInitialized then
  begin
    if FOpenFileError then Exit;
    OpenLogFile;
    if not FInitialized then Exit;
    System.WriteLn(FLogFile, GetTimestamp + ': Logger initialized (late). Log file: ' + FLogFilePath);
  end;

  try
    System.WriteLn(FLogFile, GetTimestamp + ': ' + Message);
    Flush(FLogFile);
  except
    // Silently ignore
  end;
end;

procedure TLogger.Log(const Key: string; const Value: UnicodeString);
begin
  // Free Vision's UnicodeString might be a distinct type.
  // For logging, convert to standard FPC string if necessary, or handle directly.
  // Assuming FV's UnicodeString is compatible with FPC's for WriteLn or can be cast.
  Log(Key + ': "' + string(Value) + '"'); // Explicit cast to string for safety
end;

procedure TLogger.Log(const Key: string; const Value: string); // Ansi/UTF8 String
begin
  Log(Key + ': "' + Value + '"');
end;

procedure TLogger.Log(const Key: string; const Value: ShortString);
begin
  Log(Key + ': "' + string(Value) + '"'); // Cast ShortString to String
end;

{
procedure TLogger.Log(const Key: string; const Value: Integer);
begin
  Log(Key + ': ' + IntToStr(Value));
end;
}

procedure TLogger.Log(const Key: string; const Value: Word);
begin
  Log(Key + ': ' + IntToStr(Value));
end;

procedure TLogger.Log(const Key: string; const Value: LongInt);
begin
  Log(Key + ': ' + IntToStr(Value));
end;

procedure TLogger.Log(const Key: string; const Value: Boolean);
begin
  if Value then
    Log(Key + ': True')
  else
    Log(Key + ': False');
end;

procedure TLogger.Log(const Key: string; const Value: Pointer);
begin
  Log(Key + ': ' + SysUtils.Format('$%p', [Value]));
end;

procedure TLogger.Log(const Key: string; const R: TRect);
begin
  Log(Key + SysUtils.Format(': TRect(A=(%d,%d), B=(%d,%d)) Size=(%d,%d)',
    [R.A.X, R.A.Y, R.B.X, R.B.Y, R.B.X - R.A.X, R.B.Y - R.A.Y]));
end;

procedure TLogger.Log(const Key: string; const P: TPoint);
begin
  Log(Key + SysUtils.Format(': TPoint(X=%d, Y=%d)', [P.X, P.Y]));
end;

initialization
  Logger := TLogger.Create();
finalization
  if Assigned(Logger) then
    Logger.Free;
end.