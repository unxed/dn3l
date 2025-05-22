{$MODE OBJFPC}{$H+}
unit dblwnd;

interface

uses
  Objects, UViews, UDrivers, flpanel, SysUtils;

type
  PSeparatorView = ^TSeparatorView;
  TSeparatorView = object(TView)
    procedure Draw; virtual;
  end;

  PDoubleWindow = ^TDoubleWindow;
  TDoubleWindow = object(TWindow)
  public
    LeftPanel: PFilePanel;
    RightPanel: PFilePanel;
    Separator: PSeparatorView;
    constructor Init(var Bounds: TRect; Num: Word; Drive1, Drive2: Byte);
    destructor Done; virtual;
  end;

implementation

uses Crt; // Для WriteLn

{ TSeparatorView }
procedure TSeparatorView.Draw;
var
  B: TDrawBuffer;
  ColorValue, DebugTextColor: Byte;
  i: Integer;
  S: String;
  {$IFDEF UNIX}
  VerticalLineChar : WideChar = WideChar($2502);
  {$ELSE}
  VerticalLineChar : AnsiChar = #179;
  {$ENDIF}
begin
  ColorValue := GetColor(2); // Попробуем цвет $2F (синий на сером в стандартной палитре)
  DebugTextColor := GetColor(3); //

  // Заливка для отладки
  for i := 0 to Size.Y - 1 do
  begin
    MoveChar(B, 'S', ColorValue, Size.X); // 'S' для Separator
    WriteLine(0, i, Size.X, 1, B);
  end;

  // Вертикальная линия
  if Size.X > 0 then
  begin
    for i := 0 to Size.Y - 1 do
    begin
      MoveChar(B[0], VerticalLineChar, ColorValue, 1);
      WriteLine(0, i, 1, 1, B); // Рисуем только один столбец с линией
    end;
  end;

  S := 'Sep(' + IntToStr(Size.X) + ',' + IntToStr(Size.Y) + ')@(' + IntToStr(Origin.X) + ',' + IntToStr(Origin.Y) + ')';
  if (Size.X >= Length(S)) and (Size.Y > 0) then
  begin
    // Очистим место под текст цветом фона текста
    MoveChar(B, ' ', DebugTextColor, Length(S));
    MoveStr(B, S, DebugTextColor);
    WriteLine(0, 0, Length(S), 1, B);
  end;
end;

{ TDoubleWindow }
constructor TDoubleWindow.Init(var Bounds: TRect; Num: Word; Drive1, Drive2: Byte);
var
  R: TRect;
  SepWidth: Integer;
  ClientR: TRect;
  AvailableWidth, PanelWidth, LeftPanelEndX, SeparatorEndX: Integer;
begin
  inherited Init(Bounds, 'DOS Navigator Like Prototype', wnNoNumber);
  Palette := wpCyanWindow; // Можно явно задать палитру для окна

  WriteLn('--- TDoubleWindow.Init ---');
  WriteLn('Initial Bounds: (', Bounds.A.X, ',', Bounds.A.Y, ')-(', Bounds.B.X, ',', Bounds.B.Y, ')');

  GetExtent(ClientR);
  WriteLn('ClientR before Grow(-1,-1): (', ClientR.A.X, ',', ClientR.A.Y, ')-(', ClientR.B.X, ',', ClientR.B.Y, ')');
  ClientR.Grow(-1, -1);
  WriteLn('ClientR after Grow(-1,-1): (', ClientR.A.X, ',', ClientR.A.Y, ')-(', ClientR.B.X, ',', ClientR.B.Y, ')');
  WriteLn('Window Size (Size.X, Size.Y): (', Size.X, ',', Size.Y, ')'); // Size окна после Init

  SepWidth := 1;
  AvailableWidth := ClientR.B.X - ClientR.A.X;
  PanelWidth := (AvailableWidth - SepWidth) div 2;

  WriteLn('SepWidth: ', SepWidth, ', AvailableWidth: ', AvailableWidth, ', PanelWidth (calculated): ', PanelWidth);

  // Левая панель
  R.A.X := ClientR.A.X;
  R.A.Y := ClientR.A.Y;
  R.B.X := ClientR.A.X + PanelWidth; // Конечная точка не включается, поэтому + PanelWidth
  R.B.Y := ClientR.B.Y;

  WriteLn('Attempting LeftPanel R: (', R.A.X, ',', R.A.Y, ')-(', R.B.X, ',', R.B.Y, ')');
  if (R.A.X >= R.B.X) or (R.A.Y >= R.B.Y) then
    WriteLn('ERROR: LeftPanel has invalid dimensions BEFORE creation!')
  else
  begin
    LeftPanel := New(PFilePanel, Init(R, 0, nil));
    if Assigned(LeftPanel) then
    begin
      Insert(LeftPanel);
      WriteLn('LeftPanel CREATED. Origin: (', LeftPanel^.Origin.X, ',', LeftPanel^.Origin.Y, ') Size: (', LeftPanel^.Size.X, ',', LeftPanel^.Size.Y, ')');
    end else WriteLn('ERROR: LeftPanel is NIL after New!');
  end;
  LeftPanelEndX := LeftPanel^.Origin.X + LeftPanel^.Size.X;

  // Разделитель
  R.A.X := LeftPanelEndX;
  R.A.Y := ClientR.A.Y;
  R.B.X := R.A.X + SepWidth;
  R.B.Y := ClientR.B.Y;

  WriteLn('Attempting Separator R: (', R.A.X, ',', R.A.Y, ')-(', R.B.X, ',', R.B.Y, ')');
  if (R.A.X >= R.B.X) or (R.A.Y >= R.B.Y) then
    WriteLn('ERROR: Separator has invalid dimensions BEFORE creation!')
  else
  begin
    Separator := New(PSeparatorView, Init(R));
    if Assigned(Separator) then
    begin
      Insert(Separator);
      WriteLn('Separator CREATED. Origin: (', Separator^.Origin.X, ',', Separator^.Origin.Y, ') Size: (', Separator^.Size.X, ',', Separator^.Size.Y, ')');
    end else WriteLn('ERROR: Separator is NIL after New!');
  end;
  SeparatorEndX := Separator^.Origin.X + Separator^.Size.X;

  // Правая панель
  R.A.X := SeparatorEndX;
  R.A.Y := ClientR.A.Y;
  R.B.X := ClientR.B.X; // Должна занять всю оставшуюся ширину клиентской области
  R.B.Y := ClientR.B.Y;

  WriteLn('Attempting RightPanel R: (', R.A.X, ',', R.A.Y, ')-(', R.B.X, ',', R.B.Y, ')');
  if (R.A.X >= R.B.X) or (R.A.Y >= R.B.Y) then
    WriteLn('ERROR: RightPanel has invalid dimensions BEFORE creation!')
  else
  begin
    RightPanel := New(PFilePanel, Init(R, 1, nil));
    if Assigned(RightPanel) then
    begin
      Insert(RightPanel);
      WriteLn('RightPanel CREATED. Origin: (', RightPanel^.Origin.X, ',', RightPanel^.Origin.Y, ') Size: (', RightPanel^.Size.X, ',', RightPanel^.Size.Y, ')');
    end else WriteLn('ERROR: RightPanel is NIL after New!');
  end;

  WriteLn('--- TDoubleWindow.Init END ---');
  // ReadKey;
end;

destructor TDoubleWindow.Done;
begin
  inherited Done;
end;

end.