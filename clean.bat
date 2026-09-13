@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Script de nettoyage pour DeepSeekTray
REM Supprime le dossier build et tous les artefacts de compilation
REM ============================================================================

echo.
echo ============================================================================
echo  DeepSeekTray - Nettoyage
echo ============================================================================
echo.

REM Configuration (doit correspondre a build.bat)
set "PROJECT_NAME=DeepSeekTray"
set "SOURCE_DIR=src"
set "BUILD_DIR=build"
set "OUTPUT_FILE=%BUILD_DIR%\%PROJECT_NAME%.exe"

REM Verifier que le dossier build existe
if not exist "%BUILD_DIR%" (
    echo [INFO] Le dossier "%BUILD_DIR%" n'existe pas. Rien a nettoyer.
    echo.
    pause
    exit /b 0
)

REM Afficher ce qui va etre supprime
echo [INFO] Contenu du dossier "%BUILD_DIR%" :
echo.
dir /b "%BUILD_DIR%"
echo.

REM Confirmation utilisateur
set /p CONFIRM="Confirmer la suppression de "%BUILD_DIR%" ? (O/N) : "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo [INFO] Nettoyage annule.
    echo.
    pause
    exit /b 0
)

REM Suppression du dossier build
echo.
echo [INFO] Suppression de "%BUILD_DIR%"...
rmdir /s /q "%BUILD_DIR%"

if exist "%BUILD_DIR%" (
    echo [ERREUR] Impossible de supprimer "%BUILD_DIR%"
    echo         Verifiez qu'aucun programme n'utilise les fichiers.
    echo.
    pause
    exit /b 1
)

REM Suppression des fichiers temporaires PureBasic eventuels
if exist "%SOURCE_DIR%\*.pbp" (
    echo [INFO] Le projet .pbp source n'est pas touche.
)

REM Suppression d'un eventuel dossier PureBasic temp
if exist "PureBasic_Compilation*.exe" (
    del /q "PureBasic_Compilation*.exe" 2>nul
)

echo.
echo ============================================================================
echo  Nettoyage termine !
echo ============================================================================
echo.
echo  Dossier supprime : %BUILD_DIR%\
echo.

pause
endlocal
exit /b 0

