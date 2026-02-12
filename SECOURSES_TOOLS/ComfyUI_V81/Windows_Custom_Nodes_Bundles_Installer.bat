@echo off
setlocal enabledelayedexpansion

set UV_SKIP_WHEEL_FILENAME_CHECK=1
set UV_LINK_MODE=copy

REM ========================================
REM ComfyUI Custom Node Installer v2.0
REM Modular design with Bundle support
REM ========================================

REM Initialize all node flags
set "install_swarm=0"
set "install_kjnodes=0"
set "install_impact=0"
set "install_reactor=0"
set "install_ltxvideo=0"
set "install_customscripts=0"
set "install_rgthree=0"
set "install_videohelper=0"
set "install_wasnodes=0"
set "install_melbandroformer=0"
set "install_cachedit=0"

echo ========================================
echo ComfyUI Custom Node Installer v2.0
echo ========================================
echo.
echo INDIVIDUAL NODES:
echo   1. SwarmUI ExtraNodes (SwarmComfyCommon ^& SwarmComfyExtra)
echo   2. ComfyUI-KJNodes (Kijai)
echo   3. ComfyUI-Impact-Pack
echo   4. ComfyUI-ReActor (with Impact-Pack dependency)
echo   5. ComfyUI-LTXVideo (Lightricks)
echo   6. ComfyUI-Custom-Scripts (pythongosssss)
echo   7. rgthree-comfy
echo   8. ComfyUI-VideoHelperSuite
echo   9. WAS Node Suite
echo  10. ComfyUI-MelBandRoFormer
echo  11. ComfyUI-CacheDiT
echo.
echo BUNDLES:
echo  100. LTX Audio to Video Bundle
echo       (Includes: KJNodes + LTXVideo + Custom-Scripts + rgthree + 
echo        VideoHelperSuite + WAS Nodes + MelBandRoFormer)
echo.
echo ========================================
echo.
echo Selection Options:
echo   - Single: 1
echo   - Multiple: 1,2,3 or 1 2 3 or 1, 2, 3
echo   - Range: 1-3 or 5-7
echo   - Mixed: 1,3-5,7 or 1 3-5 7
echo   - Bundle: 100
echo   - All individual nodes: 'all' or 'a'
echo.
echo ========================================
echo.

set /p selection="Enter your selection: "

REM Trim spaces
set "selection=%selection: =%"

REM Convert to lowercase for 'all' check
set "selection_lower=%selection%"

REM Check for 'all' or 'a' - installs all individual nodes
if /i "%selection_lower%"=="all" set "selection=1,2,3,4,5,6,7,8,9,10,11"
if /i "%selection_lower%"=="a" set "selection=1,2,3,4,5,6,7,8,9,10,11"

REM Replace commas and hyphens with spaces for easier parsing
set "selection=%selection:,= %"
set "selection=%selection:-= - %"

REM Process the selection
for %%i in (%selection%) do (
    if "%%i"=="-" (
        set "range_mode=1"
    ) else if defined range_mode (
        REM Handle range end
        for /L %%r in (!range_start!,1,%%i) do (
            call :mark_selection %%r
        )
        set "range_mode="
        set "range_start="
    ) else (
        set "range_start=%%i"
        call :mark_selection %%i
    )
)

REM Display selected nodes
echo.
echo ========================================
echo Selected nodes to install:
echo ========================================
if %install_swarm%==1 echo   [X] SwarmUI ExtraNodes
if %install_kjnodes%==1 echo   [X] ComfyUI-KJNodes
if %install_impact%==1 echo   [X] ComfyUI-Impact-Pack
if %install_reactor%==1 echo   [X] ComfyUI-ReActor
if %install_ltxvideo%==1 echo   [X] ComfyUI-LTXVideo
if %install_customscripts%==1 echo   [X] ComfyUI-Custom-Scripts
if %install_rgthree%==1 echo   [X] rgthree-comfy
if %install_videohelper%==1 echo   [X] ComfyUI-VideoHelperSuite
if %install_wasnodes%==1 echo   [X] WAS Node Suite
if %install_melbandroformer%==1 echo   [X] ComfyUI-MelBandRoFormer
if %install_cachedit%==1 echo   [X] ComfyUI-CacheDiT
echo ========================================
echo.

set /p confirm="Proceed with installation? (Y/N, default Y): "
if /i "%confirm%"=="N" (
    echo Installation cancelled.
    pause
    exit /b 0
)

REM Navigate to ComfyUI directory
cd ComfyUI

REM Activate virtual environment
call .\venv\Scripts\activate.bat

REM Navigate to custom_nodes
cd custom_nodes

REM ========================================
REM INSTALLATION FUNCTIONS
REM ========================================

REM Install SwarmUI ExtraNodes
if %install_swarm%==1 (
    call :install_swarm
)

REM Install ComfyUI-KJNodes
if %install_kjnodes%==1 (
    call :install_kjnodes
)

REM Install ComfyUI-Impact-Pack
if %install_impact%==1 (
    call :install_impact
)

REM Install ComfyUI-ReActor
if %install_reactor%==1 (
    call :install_reactor
)

REM Install ComfyUI-LTXVideo
if %install_ltxvideo%==1 (
    call :install_ltxvideo
)

REM Install ComfyUI-Custom-Scripts
if %install_customscripts%==1 (
    call :install_customscripts
)

REM Install rgthree-comfy
if %install_rgthree%==1 (
    call :install_rgthree
)

REM Install ComfyUI-VideoHelperSuite
if %install_videohelper%==1 (
    call :install_videohelper
)

REM Install WAS Node Suite
if %install_wasnodes%==1 (
    call :install_wasnodes
)

REM Install ComfyUI-MelBandRoFormer
if %install_melbandroformer%==1 (
    call :install_melbandroformer
)

REM Install ComfyUI-CacheDiT
if %install_cachedit%==1 (
    call :install_cachedit
)

REM ========================================
REM Final setup
REM ========================================
cd ..

echo.
echo ========================================
echo Installing/updating main requirements...
echo ========================================
uv pip install -r requirements.txt

REM Install onnxruntime-gpu if ReActor was selected
if %install_reactor%==1 (
    echo Installing onnxruntime-gpu for ReActor...
    uv pip install onnxruntime-gpu==1.22.0
)

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Installed nodes:
if %install_swarm%==1 (
    echo   - SwarmComfyCommon
    echo   - SwarmComfyExtra
)
if %install_kjnodes%==1 echo   - ComfyUI-KJNodes
if %install_impact%==1 echo   - ComfyUI-Impact-Pack
if %install_reactor%==1 (
    echo   - ComfyUI-ReActor
    echo   - ComfyUI-Impact-Pack ^(dependency^)
)
if %install_ltxvideo%==1 echo   - ComfyUI-LTXVideo
if %install_customscripts%==1 echo   - ComfyUI-Custom-Scripts
if %install_rgthree%==1 echo   - rgthree-comfy
if %install_videohelper%==1 echo   - ComfyUI-VideoHelperSuite
if %install_wasnodes%==1 echo   - WAS Node Suite
if %install_melbandroformer%==1 echo   - ComfyUI-MelBandRoFormer
if %install_cachedit%==1 echo   - ComfyUI-CacheDiT
echo.
echo ========================================

cd ..

pause
exit /b 0

REM ========================================
REM SELECTION MARKING FUNCTION
REM ========================================
:mark_selection
if "%1"=="1" set "install_swarm=1"
if "%1"=="2" set "install_kjnodes=1"
if "%1"=="3" set "install_impact=1"
if "%1"=="4" set "install_reactor=1"
if "%1"=="5" set "install_ltxvideo=1"
if "%1"=="6" set "install_customscripts=1"
if "%1"=="7" set "install_rgthree=1"
if "%1"=="8" set "install_videohelper=1"
if "%1"=="9" set "install_wasnodes=1"
if "%1"=="10" set "install_melbandroformer=1"
if "%1"=="11" set "install_cachedit=1"

REM Bundle: LTX Audio to Video
if "%1"=="100" (
    echo Activating LTX Audio to Video Bundle...
    set "install_kjnodes=1"
    set "install_ltxvideo=1"
    set "install_customscripts=1"
    set "install_rgthree=1"
    set "install_videohelper=1"
    set "install_wasnodes=1"
    set "install_melbandroformer=1"
)
exit /b 0

REM ========================================
REM INSTALLATION SUBROUTINES
REM ========================================

:install_swarm
echo.
echo ========================================
echo Installing SwarmUI ExtraNodes...
echo ========================================

REM Remove existing SwarmComfyCommon if it exists
if exist SwarmComfyCommon (
    echo Removing existing SwarmComfyCommon...
    rmdir /s /q SwarmComfyCommon
)

echo Downloading SwarmUI ExtraNodes ^(SwarmComfyCommon and SwarmComfyExtra^)...

REM Clone SwarmUI with sparse checkout
git clone --depth 1 --filter=blob:none --sparse https://github.com/mcmonkeyprojects/SwarmUI
cd SwarmUI
git sparse-checkout set --no-cone src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyExtra

REM Explicitly checkout to materialize the files
git checkout

REM Verify SwarmComfyCommon exists before copying
if not exist "src\BuiltinExtensions\ComfyUIBackend\ExtraNodes\SwarmComfyCommon" (
    echo Error: SwarmComfyCommon directory not found after checkout
    dir "src\BuiltinExtensions\ComfyUIBackend\ExtraNodes"
    pause
    exit /b 1
)

REM Copy both nodes
xcopy /E /I /Y "src\BuiltinExtensions\ComfyUIBackend\ExtraNodes\SwarmComfyCommon" "..\SwarmComfyCommon"
xcopy /E /I /Y "src\BuiltinExtensions\ComfyUIBackend\ExtraNodes\SwarmComfyExtra" "..\SwarmComfyExtra"
cd ..

REM Clean up temporary SwarmUI folder
rmdir /s /q SwarmUI

echo SwarmUI ExtraNodes installed successfully!
exit /b 0

:install_kjnodes
echo.
echo ========================================
echo Installing ComfyUI-KJNodes...
echo ========================================

if not exist ComfyUI-KJNodes (
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes
)

cd ComfyUI-KJNodes
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-KJNodes installed successfully!
exit /b 0

:install_impact
echo.
echo ========================================
echo Installing ComfyUI-Impact-Pack...
echo ========================================

if not exist ComfyUI-Impact-Pack (
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack
)

cd ComfyUI-Impact-Pack
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-Impact-Pack installed successfully!
exit /b 0

:install_reactor
echo.
echo ========================================
echo Installing ComfyUI-ReActor...
echo ========================================

REM Install Impact-Pack dependency if not already installed
if not exist ComfyUI-Impact-Pack (
    echo Installing Impact-Pack dependency...
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack
    cd ComfyUI-Impact-Pack
    git stash
    git reset --hard
    git pull --force
    if exist requirements.txt (
        uv pip install -r requirements.txt
    )
    cd ..
)

if not exist ComfyUI-ReActor (
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor
)

cd ComfyUI-ReActor
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-ReActor installed successfully!
exit /b 0

:install_ltxvideo
echo.
echo ========================================
echo Installing ComfyUI-LTXVideo...
echo ========================================

if not exist ComfyUI-LTXVideo (
    git clone --depth 1 https://github.com/Lightricks/ComfyUI-LTXVideo
)

cd ComfyUI-LTXVideo
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-LTXVideo installed successfully!
exit /b 0

:install_customscripts
echo.
echo ========================================
echo Installing ComfyUI-Custom-Scripts...
echo ========================================

if not exist ComfyUI-Custom-Scripts (
    git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts
)

cd ComfyUI-Custom-Scripts
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
) else (
    echo No requirements.txt found, skipping pip install.
)
cd ..

echo ComfyUI-Custom-Scripts installed successfully!
exit /b 0

:install_rgthree
echo.
echo ========================================
echo Installing rgthree-comfy...
echo ========================================

if not exist rgthree-comfy (
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy
)

cd rgthree-comfy
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo rgthree-comfy installed successfully!
exit /b 0

:install_videohelper
echo.
echo ========================================
echo Installing ComfyUI-VideoHelperSuite...
echo ========================================

if not exist ComfyUI-VideoHelperSuite (
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
)

cd ComfyUI-VideoHelperSuite
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-VideoHelperSuite installed successfully!
exit /b 0

:install_wasnodes
echo.
echo ========================================
echo Installing WAS Node Suite...
echo ========================================

if not exist was-node-suite-comfyui (
    git clone --depth 1 https://github.com/ltdrdata/was-node-suite-comfyui
)

cd was-node-suite-comfyui
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo WAS Node Suite installed successfully!
exit /b 0

:install_melbandroformer
echo.
echo ========================================
echo Installing ComfyUI-MelBandRoFormer...
echo ========================================

if not exist ComfyUI-MelBandRoFormer (
    git clone --depth 1 https://github.com/kijai/ComfyUI-MelBandRoFormer
)

cd ComfyUI-MelBandRoFormer
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-MelBandRoFormer installed successfully!
exit /b 0

:install_cachedit
echo.
echo ========================================
echo Installing ComfyUI-CacheDiT...
echo ========================================

if not exist ComfyUI-CacheDiT (
    git clone --depth 1 https://github.com/Jasonzzt/ComfyUI-CacheDiT
)

cd ComfyUI-CacheDiT
git stash
git reset --hard
git pull --force

if exist install.py (
    python install.py
)

if exist requirements.txt (
    uv pip install -r requirements.txt
)
cd ..

echo ComfyUI-CacheDiT installed successfully!
exit /b 0
