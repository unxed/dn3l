{$MODE OBJFPC}{$H+}
unit hideview;

interface

uses
  Objects, UViews, UDrivers; // Убедитесь, что Objects и UViews/UDrivers здесь

type
  PHideView = ^THideView;
  THideView = object(TView)
  public
    constructor Init(var Bounds: Objects.TRect); // Явно указываем Objects.TRect
  end;

implementation

constructor THideView.Init(var Bounds: Objects.TRect);
begin
  inherited Init(Bounds);
end;

end.