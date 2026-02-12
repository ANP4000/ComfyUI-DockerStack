@echo off
setlocal

echo Starting ComfyUI (V81 stack - PyTorch 2.9.1 + CUDA 13.0)...
echo This may take a while on first build.

REM Create directories if missing
if not exist "ComfyUI/models" mkdir "ComfyUI/models"
if not exist "ComfyUI/input" mkdir "ComfyUI/input"
if not exist "ComfyUI/output" mkdir "ComfyUI/output"
if not exist "ComfyUI/custom_nodes" mkdir "ComfyUI/custom_nodes"
if not exist "ComfyUI/custom_Workflows" mkdir "ComfyUI/custom_Workflows"

REM Force a rebuild to apply the new Dockerfile changes
docker compose up --build

echo ComfyUI has been stopped.
pause
endlocal
