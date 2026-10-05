```bat
@echo off & setlocal enableextensions
title Reimposta AnyDesk

:: Verifica se lo script è in esecuzione come amministratore
:: (controlla se la chiave esiste nel registro)
reg query HKEY_USERS\S-1-5-19 >NUL || (
    echo Per favore, esegui questo script come amministratore.
    pause >NUL
    exit
)

chcp 437
:: Imposta la pagina codici

call :stop_any

:: Rimuove i file di configurazione di AnyDesk
del /f "%ALLUSERSPROFILE%\AnyDesk\service.conf"
del /f "%APPDATA%\AnyDesk\service.conf"

:: Salva il file user.conf attuale nella cartella TEMP
copy /y "%APPDATA%\AnyDesk\user.conf" "%temp%\"

:: Rimuove le vecchie miniature
rd /s /q "%temp%\thumbnails" 2>NUL

:: Copia le miniature attuali nella cartella TEMP
xcopy /c /e /h /r /y /i /k "%APPDATA%\AnyDesk\thumbnails" "%temp%\thumbnails"

:: Rimuove tutti i file dalla cartella di AnyDesk
:: (sia dal profilo di sistema che da quello dell'utente)
del /f /a /q "%ALLUSERSPROFILE%\AnyDesk\*"
del /f /a /q "%APPDATA%\AnyDesk\*"

call :start_any

:lic
:: Attende finché il file system.conf contiene la riga "ad.anynet.id="
:: (timeout di 30 secondi)
set lic_count=0

:wait_lic
find "ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" >nul 2>&1
if %errorlevel%==0 goto lic_done

timeout /t 1 >nul
set /a lic_count+=1
if %lic_count% lss 30 goto wait_lic

echo Tempo scaduto durante l'attesa del nuovo ID AnyDesk.

:lic_done

:: Ripristina i file di configurazione
call :stop_any

move /y "%temp%\user.conf" "%APPDATA%\AnyDesk\user.conf" >nul 2>&1
xcopy /c /e /h /r /y /i /k "%temp%\thumbnails" "%APPDATA%\AnyDesk\thumbnails" >nul 2>&1
rd /s /q "%temp%\thumbnails" >nul 2>&1

call :start_any

echo *********
echo Operazione completata.
echo(
goto :eof


:: ================================
:: AVVIA ANYDESK
:: ================================
:start_any
echo Avvio del servizio AnyDesk...

:: Se è già in esecuzione, non tenta di avviarlo di nuovo
sc query AnyDesk | find "RUNNING" >nul
if %errorlevel%==0 (
    echo Il servizio è già in esecuzione.
    goto open_any
)

sc start AnyDesk >nul 2>&1

:: Attende fino a 15 secondi per l'avvio
set count=0

:wait_start
sc query AnyDesk | find "RUNNING" >nul
if %errorlevel%==0 goto open_any

timeout /t 1 >nul
set /a count+=1
if %count% lss 15 goto wait_start

echo Impossibile avviare il servizio.
goto :eof


:open_any
echo Apertura dell'eseguibile...

set "AnyDesk1=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"
set "AnyDesk2=%ProgramFiles%\AnyDesk\AnyDesk.exe"

if exist "%AnyDesk1%" start "" "%AnyDesk1%"
if exist "%AnyDesk2%" start "" "%AnyDesk2%"

exit /b


:: ================================
:: ARRESTA ANYDESK
:: ================================
:stop_any
echo Arresto del servizio AnyDesk...

:: Se è già arrestato
sc query AnyDesk | find "STOPPED" >nul
if %errorlevel%==0 goto kill_proc

sc stop AnyDesk >nul 2>&1

:: Attende fino all'arresto del servizio
set count=0

:wait_stop
sc query AnyDesk | find "STOPPED" >nul
if %errorlevel%==0 goto kill_proc

timeout /t 1 >nul
set /a count+=1
if %count% lss 15 goto wait_stop

echo Il servizio non ha risposto correttamente.

:kill_proc
taskkill /f /im "AnyDesk.exe" >nul 2>&1
exit /b
```
