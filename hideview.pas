{$MODE OBJFPC}{$H+}
unit hideview;

interface

uses
  Objects, UViews, UDrivers; // Free Vision units

type
  PHideView = ^THideView;
  THideView = object(TView) // Используем object вместо class
  public
    constructor Init(var Bounds: TRect);
    // procedure HideView; virtual; // TView уже имеет Hide
    // procedure ShowView; virtual; // TView уже имеет Show
  end;

implementation

constructor THideView.Init(var Bounds: TRect);
begin
  inherited Init(Bounds);
end;

end.