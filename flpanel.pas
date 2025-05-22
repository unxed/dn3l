{$MODE OBJFPC}{$H+}
unit flpanel;

interface

uses
  SysUtils, Objects, UViews, UDrivers, flpanelx;

type
  PFilePanel = ^TFilePanel;
  TFilePanel = object(TFilePanelRoot)
  public
    PanelID: String[10]; // Добавим идентификатор для отладки
    constructor Init(var Bounds: TRect; ADrive: Integer; AScrBar: PScrollBar);
    procedure Draw; virtual;
  end;

implementation

constructor TFilePanel.Init(var Bounds: TRect; ADrive: Integer; AScrBar: PScrollBar);
begin
  inherited Init(Bounds, ADrive, AScrBar);
  Options := Options or ofFramed;
  if ADrive = 0 then // Просто для примера, чтобы различать панели
    PanelID := 'Left PNL'
  else
    PanelID := 'Right PNL';
end;

procedure TFilePanel.Draw;
var
  B: TDrawBuffer;
  ColorValue, TextColor: Byte;
  S: String;
begin
  // Сначала вызываем inherited Draw, чтобы TView / TFilePanelRoot нарисовал свой фон и рамку
  inherited Draw;

  // Теперь рисуем что-то свое поверх
  ColorValue := GetColor(1); // Цвет фона панели (можно сделать другим для теста)
  TextColor := GetColor(2);  // Цвет текста

  // Заполняем прямоугольник цветом (если inherited Draw этого не сделал или сделал не так)
  // Этот шаг может быть избыточным, если ofFramed и TView.Draw работают как надо.
  {
  MoveChar(B, ' ', ColorValue, Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
  }

  // Выведем идентификатор панели и ее размеры для отладки
  S := PanelID + ' (' + IntToStr(Size.X) + 'x' + IntToStr(Size.Y) + ')';
  MoveChar(B, ' ', TextColor, Length(S)); // Очистим место под текст цветом фона текста
  MoveStr(B, S, TextColor);
  WriteLine(1, 1, Length(S), 1, B); // Рисуем в (1,1) относительно панели

  // Выведем координаты панели для отладки
  S := 'Org:(' + IntToStr(Origin.X) + ',' + IntToStr(Origin.Y) + ')';
  MoveChar(B, ' ', TextColor, Length(S));
  MoveStr(B, S, TextColor);
  WriteLine(1, 2, Length(S), 1, B);
end;

end.