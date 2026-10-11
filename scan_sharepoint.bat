@echo off
chcp 65001 >nul
title Scan Folder SharePoint -^> CSV untuk Dashboard KK
setlocal

rem ============================================================
rem  scan_sharepoint.bat
rem  Memindai folder lokal hasil sinkron SharePoint/OneDrive
rem  lalu mengexport daftar FILE dan FOLDER ke CSV untuk
rem  di-import ke Dashboard_KK_Pekalongan.html
rem
rem  CARA PAKAI:
rem   1. Sync library SharePoint ke komputer (OneDrive/SharePoint sync)
rem   2. Drag & drop folder hasil sync ke file .bat ini
rem      ATAU jalankan .bat lalu tempel alamat folder
rem   3. File sharepoint_files.csv dibuat di folder .bat ini
rem   4. Buka Dashboard_KK_Pekalongan.html -^> Import CSV SharePoint
rem
rem  Kolom CSV: Type,Path,Folder,File,Ext,SizeBytes,Modified
rem  (PowerShell dipakai bila tersedia; jika tidak, mode batch murni)
rem ============================================================

set "TARGET=%~1"
if "%TARGET%"=="" set /p "TARGET=Tempel alamat folder hasil sync SharePoint lalu tekan Enter: "
rem buang tanda kutip jika pengguna menempel path beserta kutip
set "TARGET=%TARGET:"=%"
if "%TARGET%"=="" (
  echo.
  echo [BATAL] Tidak ada folder yang dimasukkan.
  pause
  exit /b 1
)
rem bila yang di-drop adalah sebuah file, pakai folder induknya
if exist "%TARGET%" if not exist "%TARGET%\" if not "%~1"=="" set "TARGET=%~dp1"

if not exist "%TARGET%\" (
  echo.
  echo [ERROR] Folder tidak ditemukan:
  echo    %TARGET%
  echo.
  echo Pastikan folder SharePoint sudah di-sync ke komputer ini
  echo ^(buka SharePoint di browser -^> Sync, atau buka folder melalui OneDrive^).
  pause
  exit /b 1
)

set "OUT=%~dp0sharepoint_files.csv"
if exist "%OUT%" del "%OUT%" >nul 2>nul

echo Memindai: %TARGET%
echo.

where powershell.exe >nul 2>nul
if %errorlevel%==0 goto :USEPS

rem ---------- Fallback: batch murni ----------
:GOWITHBATCH
echo Type,Path,Folder,File,Ext,SizeBytes,Modified>"%OUT%"
for /f "delims=" %%D in ('dir /s /b /ad "%TARGET%" 2^>nul') do >>"%OUT%" echo "Folder","%%~fD","%%~dpD","%%~nxD","","","%%~tD"
for /f "delims=" %%F in ('dir /s /b /a-d "%TARGET%" 2^>nul') do >>"%OUT%" echo "File","%%~fF","%%~dpF","%%~nxF","%%~xF",%%~zF,"%%~tF"
if not exist "%OUT%" (
  echo [ERROR] Gagal membaca isi folder.
  pause
  exit /b 1
)
goto :DONE

rem ---------- Jalur utama: PowerShell ----------
:USEPS
set "KK_ROOT=%TARGET%"
set "KK_OUT=%OUT%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $root=$env:KK_ROOT; $out=$env:KK_OUT; $dirs=Get-ChildItem -LiteralPath $root -Recurse -Directory -Force | ForEach-Object { [pscustomobject]@{Type='Folder';Path=$_.FullName;Folder=$_.Parent.FullName;File='';Ext='';SizeBytes=0;Modified=$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')} }; $files=Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object { $_.Name -notlike '~$*' -and $_.Name -ne 'desktop.ini' -and $_.Name -ne 'Thumbs.db' -and $_.Name -ne '.DS_Store' } | ForEach-Object { [pscustomobject]@{Type='File';Path=$_.FullName;Folder=$_.DirectoryName;File=$_.Name;Ext=$_.Extension.TrimStart('.');SizeBytes=$_.Length;Modified=$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')} }; $dirs+$files | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8"
if not exist "%OUT%" (
  echo [INFO] PowerShell gagal, beralih ke mode batch...
  goto :GOWITHBATCH
)

rem ---------- Hitung baris hasil (aman utk path berspasi) ----------
:DONE
setlocal EnableDelayedExpansion
set "LINES=0"
for /f "delims=" %%C in ('type "%OUT%"') do set /a LINES+=1
set /a LINES-=1
endlocal & set "LINES=%LINES%"

echo.
echo ============================================================
echo  Selesai. %LINES% baris tercatat ^(file + folder^).
echo  Hasil: %OUT%
echo.
echo  Langkah berikutnya:
echo   1. Buka Dashboard_KK_Pekalongan.html
echo   2. Klik "Import CSV SharePoint" -^> pilih sharepoint_files.csv
echo   3. Klik "Petakan Keyword Otomatis", lalu cek hasil pemetaan
echo ============================================================
pause
