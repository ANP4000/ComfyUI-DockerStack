@echo off
setlocal EnableDelayedExpansion
title ComfyUI VRAM Optimized Launcher

:MENU
cls
echo ========================================================================
echo                  ComfyUI VRAM Optimization Launcher
echo ========================================================================
echo.
echo Select your system's VRAM/RAM configuration:
echo.
echo  [1] GPU-ONLY Mode        - High VRAM - Everything on GPU
echo  [2] HIGHVRAM Mode        - High VRAM - Models stay in GPU
echo  [3] NORMALVRAM Mode      - Normal VRAM - Standard operation
echo  [4] LOWVRAM Mode         - Low VRAM - Splits UNet for less VRAM
echo  [5] NOVRAM Mode          - Extreme low VRAM - Useful for long video generations or if you get OOM
echo  [6] CPU Mode             - No GPU / Less than 4GB VRAM - CPU only (SLOW)
echo.
echo  [7] CUSTOM Mode          - Advanced: Configure all options manually
echo.
echo  [0] Exit
echo.
echo ========================================================================
set /p choice="Enter your choice (0-7): "

if "%choice%"=="0" goto :END
if "%choice%"=="1" goto :GPU_ONLY
if "%choice%"=="2" goto :HIGHVRAM
if "%choice%"=="3" goto :NORMALVRAM
if "%choice%"=="4" goto :LOWVRAM
if "%choice%"=="5" goto :NOVRAM
if "%choice%"=="6" goto :CPU_MODE
if "%choice%"=="7" goto :CUSTOM
goto :MENU

:GPU_ONLY
cls
echo ========================================================================
echo GPU-ONLY Mode Selected
echo ========================================================================
echo Configuration: High VRAM (16GB+)
echo - Keeps ALL models on GPU (CLIP, VAE, UNet)
echo - Fastest performance
echo - Maximum VRAM usage
echo ========================================================================
set VRAM_ARGS=--gpu-only
goto :CACHE_SELECT

:HIGHVRAM
cls
echo ========================================================================
echo HIGHVRAM Mode Selected
echo ========================================================================
echo Configuration: High VRAM (12-16GB)
echo - Keeps models in GPU memory after use
echo - No CPU offloading
echo - Fast performance with good VRAM usage
echo ========================================================================
set VRAM_ARGS=--highvram
goto :CACHE_SELECT

:NORMALVRAM
cls
echo ========================================================================
echo NORMALVRAM Mode Selected
echo ========================================================================
echo Configuration: Normal VRAM (8-12GB)
echo - Default balanced operation
echo - Models unload to CPU RAM when not in use
echo - Good balance of speed and VRAM usage
echo ========================================================================
set VRAM_ARGS=--normalvram
goto :CACHE_SELECT

:LOWVRAM
cls
echo ========================================================================
echo LOWVRAM Mode Selected
echo ========================================================================
echo Configuration: Low VRAM (6-8GB)
echo - Splits UNet into parts to reduce VRAM usage
echo - Models offload to CPU RAM aggressively
echo - Slower but works with less VRAM
echo ========================================================================
set VRAM_ARGS=--lowvram
goto :CACHE_SELECT

:NOVRAM
cls
echo ========================================================================
echo NOVRAM Mode Selected
echo ========================================================================
echo Configuration: Very Low VRAM (4-6GB)
echo - Extreme model splitting and offloading
echo - For when LOWVRAM isn't enough
echo - Significantly slower but minimal VRAM usage
echo ========================================================================
set VRAM_ARGS=--novram
goto :CACHE_SELECT

:CPU_MODE
cls
echo ========================================================================
echo CPU Mode Selected
echo ========================================================================
echo Configuration: No GPU / Less than 4GB VRAM
echo - All processing on CPU (VERY SLOW)
echo - Minimal VRAM usage
echo - Only use if GPU is unavailable
echo ========================================================================
set VRAM_ARGS=--cpu
goto :CACHE_SELECT

:CACHE_SELECT
echo.
echo ========================================================================
echo Cache Configuration
echo ========================================================================
echo Cache affects RAM usage and execution speed:
echo.
echo  [1] Classic Cache      - Default, aggressive caching (Balanced)
echo  [2] LRU Cache          - Cache last N results (More RAM/VRAM)
echo  [3] No Cache           - Minimal RAM/VRAM usage (Slower, re-runs nodes)
echo  [4] RAM Pressure Cache - Auto-manages based on RAM availability
echo.
echo ========================================================================
set /p cache_choice="Select cache mode (1-4, default 1): "

if "%cache_choice%"=="" set cache_choice=1
if "%cache_choice%"=="1" set CACHE_ARGS=--cache-classic
if "%cache_choice%"=="2" (
    set /p lru_size="Enter LRU cache size [2-20, default 5]: "
    if "!lru_size!"=="" set lru_size=5
    set CACHE_ARGS=--cache-lru !lru_size!
)
if "%cache_choice%"=="3" set CACHE_ARGS=--cache-none
if "%cache_choice%"=="4" (
    set /p ram_headroom="Enter RAM headroom in GB [1-8, default 4]: "
    if "!ram_headroom!"=="" set ram_headroom=4
    set CACHE_ARGS=--cache-ram !ram_headroom!
)

:SMART_MEMORY
echo.
echo ========================================================================
echo Smart Memory Management
echo ========================================================================
echo Smart memory keeps models in VRAM when possible.
echo Disable for more aggressive RAM offloading (reduces VRAM usage).
echo.
set /p smart_mem="Disable Smart Memory? (y/N, default N): "
set SMART_MEM_ARGS=
if /i "%smart_mem%"=="y" set SMART_MEM_ARGS=--disable-smart-memory

:VAE_SELECT
echo.
echo ========================================================================
echo VAE Processing Location
echo ========================================================================
echo VAE can use significant VRAM. Running on CPU frees VRAM for UNet.
echo.
echo  [1] GPU (Default) - Faster but uses VRAM
echo  [2] CPU           - Slower but frees ~500MB-1GB VRAM
echo.
set /p vae_choice="Select VAE location (1-2, default 1): "
set VAE_ARGS=
if "%vae_choice%"=="2" set VAE_ARGS=--cpu-vae

:ATTENTION_SELECT
echo.
echo ========================================================================
echo Attention Mechanism
echo ========================================================================
echo Different attention methods affect speed and VRAM usage:
echo.
echo  [1] Sage Attention       - Recommended (Fast, efficient)
echo  [2] Flash Attention      - Very fast on supported GPUs
echo  [3] PyTorch Attention    - PyTorch 2.0 native (Good compatibility)
echo  [4] Split Attention      - Lower VRAM usage (Slower)
echo  [5] Quad Attention       - Sub-quadratic optimization
echo  [6] xFormers (Default)   - Auto-selected if available
echo.
set /p attn_choice="Select attention method (1-6, default 1): "

if "%attn_choice%"=="" set attn_choice=1
set ATTN_ARGS=
if "%attn_choice%"=="1" set ATTN_ARGS=--use-sage-attention
if "%attn_choice%"=="2" set ATTN_ARGS=--use-flash-attention
if "%attn_choice%"=="3" set ATTN_ARGS=--use-pytorch-cross-attention
if "%attn_choice%"=="4" set ATTN_ARGS=--use-split-cross-attention
if "%attn_choice%"=="5" set ATTN_ARGS=--use-quad-cross-attention
if "%attn_choice%"=="6" set ATTN_ARGS=

:PRECISION_SELECT
echo.
echo ========================================================================
echo UNet Precision
echo ========================================================================
echo Lower precision = Less VRAM usage but may affect quality:
echo.
echo  [1] Auto (Default)  - Let ComfyUI decide
echo  [2] FP16            - Half precision (Saves ~50 percent VRAM)
echo  [3] BF16            - BFloat16 (Good balance, needs newer GPU)
echo  [4] FP8 (e4m3fn)    - 8-bit float (Maximum savings, newest GPUs)
echo  [5] FP32            - Full precision (Maximum quality, most VRAM)
echo.
set /p prec_choice="Select UNet precision (1-5, default 1): "

if "%prec_choice%"=="" set prec_choice=1
set PRECISION_ARGS=
if "%prec_choice%"=="2" set PRECISION_ARGS=--fp16-unet
if "%prec_choice%"=="3" set PRECISION_ARGS=--bf16-unet
if "%prec_choice%"=="4" set PRECISION_ARGS=--fp8_e4m3fn-unet
if "%prec_choice%"=="5" set PRECISION_ARGS=--fp32-unet

:ASYNC_OFFLOAD
echo.
echo ========================================================================
echo Async Weight Offloading
echo ========================================================================
echo Async offloading moves models between GPU/CPU faster (Nvidia default).
echo Disable if you experience issues.
echo.
set /p async_off="Disable Async Offloading? (y/N, default N): "
set ASYNC_ARGS=
if /i "%async_off%"=="y" set ASYNC_ARGS=--disable-async-offload

:EXTRA_OPTIONS
echo.
echo ========================================================================
echo Additional Optimizations
echo ========================================================================
set /p reserve_vram="Reserve VRAM for OS in GB (0-4, default 0 = auto): "
set RESERVE_ARGS=
if not "%reserve_vram%"=="" if not "%reserve_vram%"=="0" set RESERVE_ARGS=--reserve-vram %reserve_vram%

echo.
set /p pin_mem="Disable pinned memory? (May reduce VRAM) (y/N, default N): "
set PIN_ARGS=
if /i "%pin_mem%"=="y" set PIN_ARGS=--disable-pinned-memory

goto :RUN_COMFY

:CUSTOM
cls
echo ========================================================================
echo CUSTOM Configuration Mode
echo ========================================================================
echo Configure all options manually for advanced users.
echo ========================================================================
echo.
echo VRAM Mode Options:
echo  [1] --gpu-only      : Keep everything on GPU
echo  [2] --highvram      : Keep models in GPU
echo  [3] --normalvram    : Standard mode
echo  [4] --lowvram       : Split UNet
echo  [5] --novram        : Extreme splitting
echo  [6] --cpu           : CPU only (No GPU)
echo.
set "VRAM_ARGS="
set "vram_mapped=0"
set /p vram_input="Select VRAM mode (1-6, or enter custom arg): "
if "%vram_input%"=="1" (
    set "VRAM_ARGS=--gpu-only"
    set "vram_mapped=1"
)
if "%vram_input%"=="2" (
    set "VRAM_ARGS=--highvram"
    set "vram_mapped=1"
)
if "%vram_input%"=="3" (
    set "VRAM_ARGS=--normalvram"
    set "vram_mapped=1"
)
if "%vram_input%"=="4" (
    set "VRAM_ARGS=--lowvram"
    set "vram_mapped=1"
)
if "%vram_input%"=="5" (
    set "VRAM_ARGS=--novram"
    set "vram_mapped=1"
)
if "%vram_input%"=="6" (
    set "VRAM_ARGS=--cpu"
    set "vram_mapped=1"
)
if "%vram_mapped%"=="0" set "VRAM_ARGS=%vram_input%"

echo.
echo Cache Options:
echo  [1] --cache-classic : Default aggressive caching
echo  [2] --cache-lru N   : LRU cache with N items
echo  [3] --cache-none    : No caching (minimal RAM/VRAM)
echo  [4] --cache-ram GB  : RAM pressure cache with GB headroom
echo.
set "CACHE_ARGS="
set "cache_mapped=0"
set /p cache_input="Select cache mode (1-4, or enter custom arg, default 1): "
if "%cache_input%"=="" set cache_input=1
if "%cache_input%"=="1" (
    set "CACHE_ARGS=--cache-classic"
    set "cache_mapped=1"
)
if "%cache_input%"=="2" (
    set /p lru_size="Enter LRU cache size [2-20, default 5]: "
    if "!lru_size!"=="" set lru_size=5
    set "CACHE_ARGS=--cache-lru !lru_size!"
    set "cache_mapped=1"
)
if "%cache_input%"=="3" (
    set "CACHE_ARGS=--cache-none"
    set "cache_mapped=1"
)
if "%cache_input%"=="4" (
    set /p ram_headroom="Enter RAM headroom in GB [1-8, default 4]: "
    if "!ram_headroom!"=="" set ram_headroom=4
    set "CACHE_ARGS=--cache-ram !ram_headroom!"
    set "cache_mapped=1"
)
if "%cache_mapped%"=="0" set "CACHE_ARGS=%cache_input%"

echo.
echo Memory Management:
echo  [1] Disable smart memory    : Aggressive RAM offloading
echo  [2] CPU VAE                 : Run VAE on CPU
echo  [3] Reserve VRAM GB         : Reserve VRAM for OS
echo  [4] Disable pinned memory   : Disable pinned memory
echo  [5] Disable async offload   : Disable async offloading
echo.
set "MEMORY_ARGS="
set /p mem_input="Select memory options (e.g., 1 3 5) or enter custom args: "
set "mem_is_numeric=1"
for /f "delims=0123456789 " %%A in ("%mem_input%") do set "mem_is_numeric=0"
if "%mem_is_numeric%"=="1" (
    for %%M in (!mem_input!) do (
        if "%%M"=="1" set "MEMORY_ARGS=!MEMORY_ARGS! --disable-smart-memory"
        if "%%M"=="2" set "MEMORY_ARGS=!MEMORY_ARGS! --cpu-vae"
        if "%%M"=="3" (
            set /p reserve_vram="Reserve VRAM for OS in GB (0-4, default 0 = auto): "
            if "!reserve_vram!"=="" set reserve_vram=0
            if not "!reserve_vram!"=="0" set "MEMORY_ARGS=!MEMORY_ARGS! --reserve-vram !reserve_vram!"
        )
        if "%%M"=="4" set "MEMORY_ARGS=!MEMORY_ARGS! --disable-pinned-memory"
        if "%%M"=="5" set "MEMORY_ARGS=!MEMORY_ARGS! --disable-async-offload"
    )
) else (
    set "MEMORY_ARGS=%mem_input%"
)

echo.
echo Attention Methods:
echo  [1] --use-sage-attention      : Sage attention (recommended)
echo  [2] --use-flash-attention     : Flash attention
echo  [3] --use-pytorch-cross-attention : PyTorch 2.0 attention
echo  [4] --use-split-cross-attention   : Split attention (low VRAM)
echo  [5] --use-quad-cross-attention    : Quad attention
echo  [6] xFormers (Default)            : Auto-selected if available
echo.
set "ATTN_ARGS="
set "attn_mapped=0"
set /p attn_input="Select attention method (1-6, or enter custom arg, default 1): "
if "%attn_input%"=="" set attn_input=1
if "%attn_input%"=="1" (
    set "ATTN_ARGS=--use-sage-attention"
    set "attn_mapped=1"
)
if "%attn_input%"=="2" (
    set "ATTN_ARGS=--use-flash-attention"
    set "attn_mapped=1"
)
if "%attn_input%"=="3" (
    set "ATTN_ARGS=--use-pytorch-cross-attention"
    set "attn_mapped=1"
)
if "%attn_input%"=="4" (
    set "ATTN_ARGS=--use-split-cross-attention"
    set "attn_mapped=1"
)
if "%attn_input%"=="5" (
    set "ATTN_ARGS=--use-quad-cross-attention"
    set "attn_mapped=1"
)
if "%attn_input%"=="6" (
    set "ATTN_ARGS="
    set "attn_mapped=1"
)
if "%attn_mapped%"=="0" set "ATTN_ARGS=%attn_input%"

echo.
echo Precision Options:
echo  [1] Auto (Default)  : Let ComfyUI decide
echo  [2] --fp16-unet     : Half precision UNet
echo  [3] --bf16-unet     : BFloat16 UNet
echo  [4] --fp8_e4m3fn-unet : FP8 UNet (newest GPUs)
echo  [5] --fp32-unet     : Full precision UNet
echo.
set "PRECISION_ARGS="
set "precision_mapped=0"
set /p prec_input="Select precision (1-5, or enter custom arg, default 1): "
if "%prec_input%"=="" set prec_input=1
if "%prec_input%"=="1" (
    set "PRECISION_ARGS="
    set "precision_mapped=1"
)
if "%prec_input%"=="2" (
    set "PRECISION_ARGS=--fp16-unet"
    set "precision_mapped=1"
)
if "%prec_input%"=="3" (
    set "PRECISION_ARGS=--bf16-unet"
    set "precision_mapped=1"
)
if "%prec_input%"=="4" (
    set "PRECISION_ARGS=--fp8_e4m3fn-unet"
    set "precision_mapped=1"
)
if "%prec_input%"=="5" (
    set "PRECISION_ARGS=--fp32-unet"
    set "precision_mapped=1"
)
if "%precision_mapped%"=="0" set "PRECISION_ARGS=%prec_input%"

set SMART_MEM_ARGS=%MEMORY_ARGS%
set VAE_ARGS=
set ASYNC_ARGS=
set RESERVE_ARGS=
set PIN_ARGS=

goto :RUN_COMFY

:RUN_COMFY
cls
echo ========================================================================
echo Starting ComfyUI with selected optimizations...
echo ========================================================================
echo Configuration:
echo  VRAM Mode:   %VRAM_ARGS%
echo  Cache:       %CACHE_ARGS%
echo  Smart Mem:   %SMART_MEM_ARGS%
echo  VAE:         %VAE_ARGS%
echo  Attention:   %ATTN_ARGS%
echo  Precision:   %PRECISION_ARGS%
echo  Async:       %ASYNC_ARGS%
echo  Reserve:     %RESERVE_ARGS%
echo  Pin Memory:  %PIN_ARGS%
echo ========================================================================
echo.

cd ComfyUI

call .\venv\Scripts\activate.bat

echo Starting ComfyUI...
echo.

python.exe -s main.py --windows-standalone-build --auto-launch %VRAM_ARGS% %CACHE_ARGS% %SMART_MEM_ARGS% %VAE_ARGS% %ATTN_ARGS% %PRECISION_ARGS% %ASYNC_ARGS% %RESERVE_ARGS% %PIN_ARGS%

pause
goto :END

:END
exit
