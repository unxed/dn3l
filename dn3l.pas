program dn3l; // Изменено имя программы для соответствия вашему файлу

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  dnapp; // Наш основной модуль приложения

// DNApplication объявлена как PTDNApplication в dnapp.pas,
// поэтому она уже является указателем.

begin
  New(DNApplication, Init); // Правильный вызов конструктора для типа object через New
  DNApplication^.Run;      // Обращение к методам через указатель
  Dispose(DNApplication, Done); // Правильный вызов деструктора
end.