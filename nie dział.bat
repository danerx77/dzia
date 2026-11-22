@echo off
chcp 65001 >nul
setlocal EnableExtensions

rem =====================================================================
rem  Tłumacz Pokemon Decomp - v. 0.5
rem
rem  Buduje plik .exe (PyInstaller) i uruchamia program jednym kliknięciem.
rem
rem  Użycie:
rem     Tłumacz Pokemon Decomp - v. 0.5.bat         budowa (gdy trzeba) + start
rem     Tłumacz Pokemon Decomp - v. 0.5.bat build   wymusza przebudowanie .exe
rem     Tłumacz Pokemon Decomp - v. 0.5.bat run     start bez .exe (sam skrypt)
rem
rem  Gotowy plik trafia do:  dist\Translator.exe
rem =====================================================================

cd /d "%~dp0"

set "SCRIPT=translator50 (24).py"
set "EXE=dist\Translator.exe"
set "ICON=translator.ico"
set "MODE=%~1"

rem --- 1. szukamy Pythona ---------------------------------------------
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY goto no_python

if /i "%MODE%"=="run" goto run_script

rem --- 2. biblioteki: PySide6 (program) i PyInstaller (budowa .exe) ----
%PY% -c "import PySide6" >nul 2>nul
if errorlevel 1 call :install PySide6
if errorlevel 1 goto failed

%PY% -c "import PyInstaller" >nul 2>nul
if errorlevel 1 call :install pyinstaller
if errorlevel 1 goto failed

rem --- 3. czy trzeba budować plik .exe? --------------------------------
rem  Budujemy, gdy: podano 'build', brak pliku .exe albo skrypt jest nowszy.
set "BUILD="
if /i "%MODE%"=="build" set "BUILD=1"
if not exist "%EXE%" set "BUILD=1"
if not defined BUILD goto check_timestamp
goto build_exe

:check_timestamp
rem  Porównujemy daty plików - PowerShell jest w każdym Windowsie.
powershell -NoProfile -Command "exit 0" >nul 2>nul
if errorlevel 1 goto start_app
for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "if ((Test-Path '%SCRIPT%') -and (Test-Path '%EXE%')) { (Get-Item '%SCRIPT%').LastWriteTime -gt (Get-Item '%EXE%').LastWriteTime } else { $false }" 2^>nul`) do if /i "%%N"=="True" set "BUILD=1"
if not defined BUILD goto start_app

:build_exe
echo [INFO] Buduję plik .exe - to potrwa około minuty...
rem  Ikona: program sam rysuje translator.ico obok siebie (w kilku
rem  rozmiarach), dzieki czemu PyInstaller moze ja wbudowac w plik .exe.
%PY% -c "import importlib.util as u; s=u.spec_from_file_location('t50','%SCRIPT%'); m=u.module_from_spec(s); s.loader.exec_module(m); m.save_app_icon()" >nul 2>nul
if not exist "%ICON%" (
    echo [INFO] Nie udalo sie utworzyc "%ICON%" - buduje bez ikony.
    set "ICON="
)
if not defined ICON goto build_no_icon
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name "Translator" --icon "%ICON%" "%SCRIPT%"
goto build_check

:build_no_icon
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name "Translator" "%SCRIPT%"

:build_check
if not exist "%EXE%" goto build_failed
echo [OK] Zbudowano: %EXE%

rem --- 4. start programu -----------------------------------------------
:start_app
if exist "%EXE%" (
    echo [INFO] Uruchamiam %EXE%
    start "" "%EXE%"
    exit /b 0
)

:run_script
rem  Awaryjny start bez .exe - okno konsoli zostaje ukryte.
set "RUN=pyw -3"
where pyw >nul 2>nul || set "RUN=pythonw"
where pythonw >nul 2>nul || set "RUN=%PY%"
start "" %RUN% "%~dp0%SCRIPT%"

rem Ciche zamknięcie okna konsoli (program dalej działa).
exit /b 0

rem =====================================================================
rem  Procedury pomocnicze
rem =====================================================================
:no_python
echo [BLAD] Nie znaleziono Pythona w systemie.
echo        Zainstaluj Pythona 3.11 albo nowszego:
echo        https://www.python.org/downloads/
echo        a potem uruchom ten plik ponownie.
echo.
pause
exit /b 1

:install
echo [INFO] Instaluję bibliotekę %~1 ...
%PY% -m pip install --user %~1
exit /b %errorlevel%

:build_failed
echo [BLAD] Budowanie nie powiodło się - brak pliku "%EXE%".
echo.
pause
exit /b 1

:failed
echo [BLAD] Nie udało się przygotować bibliotek.
echo        Spróbuj ręcznie:  %PY% -m pip install PySide6 pyinstaller
echo.
pause
exit /b 1
