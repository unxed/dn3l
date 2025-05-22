unit xdblwnd;

interface

uses
  Objects, UViews, UDrivers, dblwnd; // dblwnd.pas теперь содержит TDoubleWindow как object

type
  PXDoubleWindow = ^TXDoubleWindow;
  TXDoubleWindow = object(TDoubleWindow) // ИЗМЕНЕНИЕ ЗДЕСЬ: class на object
  public
    constructor Init(var Bounds: TRect; Num: Word; Drive1, Drive2: Byte);
    // Здесь можно будет добавлять методы, специфичные для Dos Navigator,
    // переопределяя виртуальные методы TDoubleWindow или добавляя новые.
  end;

implementation

constructor TXDoubleWindow.Init(var Bounds: TRect; Num: Word; Drive1, Drive2: Byte);
begin
  inherited Init(Bounds, Num, Drive1, Drive2); // Вызов конструктора родительского object TDoubleWindow
end;

end.