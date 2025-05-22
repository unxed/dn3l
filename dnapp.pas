{$MODE OBJFPC}{$H+}
unit dnapp;

interface

uses
  Objects, UDrivers, UMenus, UViews, UDialogs, UApp, xdblwnd; // Убрали Commands

type
  PTDNApplication = ^TDNApplication;
  TDNApplication = object(TApplication)
  public
    constructor Init;
    procedure InitDesktop; virtual;
  end;

  PTDNDesktop = ^TDNDesktop;
  TDNDesktop = object(TDesktop)
  public
    constructor Init(var Bounds: TRect);
  end;

var
  DNApplication: PTDNApplication;

implementation

{ TDNApplication }

constructor TDNApplication.Init;
begin
  inherited Init;
end;

procedure TDNApplication.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R); // ИСПРАВЛЕНИЕ ЗДЕСЬ
  if MenuBar <> nil then Inc(R.A.Y);
  if StatusLine <> nil then Dec(R.B.Y);
  Desktop := New(PTDNDesktop, Init(R));
  Insert(Desktop);
end;

{ TDNDesktop }

constructor TDNDesktop.Init(var Bounds: TRect);
var
  Window: PXDoubleWindow;
  R: TRect;
begin
  inherited Init(Bounds);

  GetExtent(R); // ИСПРАВЛЕНИЕ ЗДЕСЬ
  Window := New(PXDoubleWindow, Init(R, 0, 0, 0));
  Insert(Window);
end;

end.