@echo off
chcp 1252 >nul
echo.
echo ============================================================================
echo  DeepSeekTray - Exécution des tests unitaires Python
echo ============================================================================
echo.

REM Vérifier que Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Python n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Python 3.x depuis https://www.python.org/
    echo.
    pause
    exit /b 1
)

echo [INFO] Python détecté. Exécution des tests...
echo.

REM Exécuter les tests
python tests\test_logic.py

echo.
echo ============================================================================
pause
