@echo off
chcp 1252 >nul
setlocal enabledelayedexpansion

REM ============================================================================
REM Script de build pour DeepSeekTray
REM Compile le projet PureBasic en version x64 avec DPI Aware
REM ============================================================================

echo.
echo ============================================================================
echo  DeepSeekTray - Script de compilation
echo ============================================================================
echo.

REM Configuration
set "PROJECT_NAME=DeepSeekTray"
set "SOURCE_DIR=src"
set "BUILD_DIR=build"
set "SOURCE_FILE=%SOURCE_DIR%\%PROJECT_NAME%.pb"
set "OUTPUT_FILE=%BUILD_DIR%\%PROJECT_NAME%.exe"

REM Vérifier que le fichier source existe
if not exist "%SOURCE_FILE%" (
    echo [ERREUR] Fichier source introuvable : %SOURCE_FILE%
    echo.
    pause
    exit /b 1
)

REM Créer le dossier build s'il n'existe pas
if not exist "%BUILD_DIR%" (
    echo [INFO] Création du dossier %BUILD_DIR%...
    mkdir "%BUILD_DIR%"
    if errorlevel 1 (
        echo [ERREUR] Impossible de créer le dossier %BUILD_DIR%
        pause
        exit /b 1
    )
)

REM Trouver le compilateur PureBasic
REM Chercher dans les emplacements standards
set "PB_COMPILER="

REM Essayer PureBasic 6.x (64-bit)
if exist "C:\Program Files\PureBasic\compilers\pbcompiler.exe" (
    set "PB_COMPILER=C:\Program Files\PureBasic\compilers\pbcompiler.exe"
    goto :found_compiler
)

REM Essayer PureBasic 5.x (64-bit)
if exist "C:\Program Files (x86)\PureBasic\compilers\pbcompiler.exe" (
    set "PB_COMPILER=C:\Program Files (x86)\PureBasic\compilers\pbcompiler.exe"
    goto :found_compiler
)

REM Essayer un chemin personnalisé (modifiable selon votre installation)
if exist "C:\PureBasic\compilers\pbcompiler.exe" (
    set "PB_COMPILER=C:\PureBasic\compilers\pbcompiler.exe"
    goto :found_compiler
)

REM Si le compilateur n'est pas trouvé, demander à l'utilisateur
echo [ERREUR] Compilateur PureBasic introuvable !
echo.
echo Veuillez modifier ce script et définir le chemin vers pbcompiler.exe
echo ou installer PureBasic dans l'un des emplacements suivants :
echo   - C:\Program Files\PureBasic\
echo   - C:\Program Files (x86)\PureBasic\
echo   - C:\PureBasic\
echo.
pause
exit /b 1

:found_compiler
echo [INFO] Compilateur trouvé : %PB_COMPILER%
echo.

REM Compilation
echo [INFO] Compilation de %PROJECT_NAME% en version x64...
echo.

REM Syntaxe officielle du compilateur PureBasic en ligne de commande
REM Note : Le mode GUI est le comportement par défaut. Ne pas utiliser /SUBSYSTEM.
"%PB_COMPILER%" ^
    /QUIET ^
    /EXE "%OUTPUT_FILE%" ^
    "%SOURCE_FILE%"

if errorlevel 1 (
    echo.
    echo [ERREUR] La compilation a échoué !
    echo.
    pause
    exit /b 1
)

REM Vérifier que l'exécutable a bien été créé
if not exist "%OUTPUT_FILE%" (
    echo.
    echo [ERREUR] L'exécutable n'a pas été généré : %OUTPUT_FILE%
    echo.
    pause
    exit /b 1
)

REM Afficher les informations sur l'exécutable
for %%A in ("%OUTPUT_FILE%") do (
    set "FILE_SIZE=%%~zA"
    set "FILE_DATE=%%~tA"
)

echo.
echo ============================================================================
echo  Compilation réussie !
echo ============================================================================
echo.
echo  Fichier généré : %OUTPUT_FILE%
echo  Taille         : %FILE_SIZE% octets
echo  Date           : %FILE_DATE%
echo.
echo ============================================================================
echo.

REM Optionnel : lancer l'exécutable
set /p LAUNCH="Voulez-vous lancer l'application ? (O/N) : "
if /i "%LAUNCH%"=="O" (
    echo.
    echo [INFO] Lancement de %PROJECT_NAME%...
    start "" "%OUTPUT_FILE%"
)

endlocal
exit /b 0
