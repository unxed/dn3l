{$MODE OBJFPC}{$H+}
unit flpanelx;

interface

uses
  Objects, UViews, UDrivers, hideview;

type
  PFilePanelRoot = ^TFilePanelRoot;
  TFilePanelRoot = object(THideView) // Используем object
  public
    constructor Init(var Bounds: TRect; ADrive: Integer; AScrBar: PScrollBar);
  end;

implementation

constructor TFilePanelRoot.Init(var Bounds: TRect; ADrive: Integer; AScrBar: PScrollBar);
begin
  inherited Init(Bounds);
  // ADrive и AScrBar пока не используются
end;

end.