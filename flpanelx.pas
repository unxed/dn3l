{$MODE OBJFPC}{$H+}
unit flpanelx;

interface

uses
  Classes, SysUtils, Objects, UViews, UDrivers, hideview; // Убедитесь, что Objects и UViews/UDrivers здесь

type
  PFilePanelRoot = ^TFilePanelRoot;
  TFilePanelRoot = object(THideView)
  public
    // Явно указываем Objects.TRect
    constructor Init(var Bounds: Objects.TRect; ADrive: Integer; AScrBar: PScrollBar);
  end;

implementation

constructor TFilePanelRoot.Init(var Bounds: Objects.TRect; ADrive: Integer; AScrBar: PScrollBar);
begin
  inherited Init(Bounds);
end;

end.