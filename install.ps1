#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ================================================================
# ComfyUI Docker Stack - Setup Wizard
# SECOURSES V81 | PyTorch 2.9.1 | CUDA 13.0
# ================================================================

# ---- Helpers ----
function Write-Step($num, $total, $msg) {
    Write-Host "`n[$num/$total] $msg" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor DarkGray
}
function Write-OK($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }

function Ask-YesNo($prompt, $default = 'Y') {
    $suffix = if ($default -eq 'Y') { "(Y/n)" } else { "(y/N)" }
    $answer = Read-Host "  $prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $default }
    return $answer -in @('Y', 'y', 'yes')
}

# ---- Banner ----
Clear-Host
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    ComfyUI Docker Stack - Setup Wizard"       -ForegroundColor Cyan
Write-Host "    SECOURSES V81 | PyTorch 2.9.1 | CUDA 13.0" -ForegroundColor DarkCyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This wizard will:"
Write-Host "    1. Check your GPU and driver compatibility"
Write-Host "    2. Verify Docker Desktop is ready"
Write-Host "    3. Test GPU passthrough"
Write-Host "    4. Set up project directories and custom nodes"
Write-Host "    5. Optionally build the Docker image"
Write-Host ""

# ================================================================
# STEP 1: NVIDIA GPU CHECK
# ================================================================
Write-Step 1 5 "Checking NVIDIA GPU"

if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
    Write-Fail "nvidia-smi not found. NVIDIA drivers are not installed."
    Write-Host "  Download from: https://www.nvidia.com/drivers" -ForegroundColor Yellow
    Read-Host "`n  Press Enter to exit"
    exit 1
}

# Query GPU info (first GPU if multiple)
try {
    $gpuQuery = nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader 2>&1
    $gpuLines = ($gpuQuery -split "`n") | Where-Object { $_.Trim() -ne "" }
    $gpuCount = $gpuLines.Count

    # Parse first GPU
    $parts = $gpuLines[0] -split ","
    $gpuName       = $parts[0].Trim()
    $driverVersion = $parts[1].Trim()
    $gpuMemory     = $parts[2].Trim()
    $computeCap    = $parts[3].Trim()
} catch {
    Write-Fail "Failed to query GPU info: $_"
    Read-Host "`n  Press Enter to exit"
    exit 1
}

Write-OK "GPU: $gpuName ($gpuMemory)"
if ($gpuCount -gt 1) {
    Write-OK "GPUs detected: $gpuCount (using first for compatibility check)"
}
Write-OK "Driver: $driverVersion"
Write-OK "Compute Capability: SM $computeCap"

# Parse versions
$ccParts = $computeCap -split '\.'
$ccMajor = [int]$ccParts[0]
$ccMinor = [int]$ccParts[1]
$ccNum   = $ccMajor * 10 + $ccMinor
$driverMajor = [int]($driverVersion -split '\.')[0]

# Driver check
if ($driverMajor -lt 570) {
    Write-Fail "Driver $driverVersion is too old for CUDA 13.0 (need 570+)."
    Write-Host "  Download latest from: https://www.nvidia.com/drivers" -ForegroundColor Yellow
    Read-Host "`n  Press Enter to exit"
    exit 1
}
Write-OK "Driver $driverVersion meets CUDA 13.0 requirement"

# Compute capability check
$compatLevel = "incompatible"
$compatNote  = ""
if ($ccNum -ge 80) {
    $compatLevel = "full"
    $compatNote  = "SageAttention + Flash Attention + xFormers"
} elseif ($ccNum -ge 75) {
    $compatLevel = "partial"
    $compatNote  = "xFormers only (no SageAttention / Flash Attention)"
} else {
    Write-Fail "Compute capability $computeCap is not supported by CUDA 13.0."
    Write-Host "  Minimum GPU: RTX 2060 / RTX 2070 / RTX 2080 (Turing, SM 7.5)" -ForegroundColor Red
    Write-Host "  Pascal (GTX 1080) and older are not supported." -ForegroundColor Red
    Read-Host "`n  Press Enter to exit"
    exit 1
}

if ($compatLevel -eq "full") {
    Write-OK "Compatibility: FULL - $compatNote"
} else {
    Write-Warn "Compatibility: PARTIAL - $compatNote"
    Write-Host "  SageAttention will be auto-disabled at runtime." -ForegroundColor DarkYellow
    Write-Host "  Everything else works normally." -ForegroundColor DarkYellow
}

# VRAM check
$vramMB = [int]($gpuMemory -replace '[^\d]', '')
if ($vramMB -lt 6000) {
    Write-Warn "Low VRAM ($gpuMemory). 6GB minimum, 12GB+ recommended."
    Write-Host "  You may need to use heavily quantized models." -ForegroundColor DarkYellow
} elseif ($vramMB -lt 12000) {
    Write-OK "VRAM: $gpuMemory (adequate - some models may need quantization)"
} else {
    Write-OK "VRAM: $gpuMemory (excellent)"
}

# ================================================================
# STEP 2: DOCKER CHECK
# ================================================================
Write-Step 2 5 "Checking Docker Desktop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Fail "Docker is not installed."
    Write-Host "  Install Docker Desktop: https://docker.com/products/docker-desktop" -ForegroundColor Yellow
    Read-Host "`n  Press Enter to exit"
    exit 1
}
Write-OK "Docker found"

# Is Docker running?
$dockerRunning = $false
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
} catch {}

if (-not $dockerRunning) {
    Write-Fail "Docker is not running. Please start Docker Desktop."
    Read-Host "`n  Press Enter to exit"
    exit 1
}
Write-OK "Docker is running"

# Docker Compose
try {
    $null = docker compose version 2>&1
    Write-OK "Docker Compose available"
} catch {
    Write-Fail "Docker Compose not found. Update Docker Desktop."
    Read-Host "`n  Press Enter to exit"
    exit 1
}

# GPU passthrough test
Write-Host "  Testing GPU passthrough (may pull a small image on first run)..." -ForegroundColor Gray
$gpuTestOutput = docker run --rm --gpus all nvidia/cuda:13.0.1-base-ubuntu22.04 nvidia-smi 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-OK "GPU passthrough working"
} else {
    Write-Fail "GPU passthrough failed."
    Write-Host "  Check Docker Desktop Settings > Resources > WSL integration" -ForegroundColor Yellow
    Write-Host "  Ensure WSL2 backend is enabled." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Error output:" -ForegroundColor DarkGray
    Write-Host "  $gpuTestOutput" -ForegroundColor DarkGray
    Read-Host "`n  Press Enter to exit"
    exit 1
}

# ================================================================
# STEP 3: COMPATIBILITY SUMMARY
# ================================================================
Write-Step 3 5 "Compatibility Summary"

$summaryColor = if ($compatLevel -eq 'full') { 'Green' } else { 'Yellow' }
Write-Host ""
Write-Host "  GPU:            $gpuName" -ForegroundColor White
Write-Host "  VRAM:           $gpuMemory" -ForegroundColor White
Write-Host "  Compute Cap:    SM $computeCap" -ForegroundColor White
Write-Host "  Driver:         $driverVersion" -ForegroundColor White
Write-Host "  Docker:         OK" -ForegroundColor White
Write-Host "  GPU Passthru:   OK" -ForegroundColor White
Write-Host "  Compatibility:  $($compatLevel.ToUpper())" -ForegroundColor $summaryColor
Write-Host ""

if (-not (Ask-YesNo "Continue with installation?")) {
    Write-Host "`n  Installation cancelled." -ForegroundColor Yellow
    exit 0
}

# ================================================================
# STEP 4: PROJECT SETUP
# ================================================================
Write-Step 4 5 "Setting up project"

# --- 4a: Create directory structure ---
Write-Host "  Creating folder structure..." -ForegroundColor Gray
$paths = @(
    "ComfyUI/models/diffusion_models",
    "ComfyUI/models/vae",
    "ComfyUI/models/text_encoders",
    "ComfyUI/models/controlnet",
    "ComfyUI/models/loras",
    "ComfyUI/models/upscale_models",
    "ComfyUI/models/clip_vision",
    "ComfyUI/models/style_models",
    "ComfyUI/models/embeddings",
    "ComfyUI/models/audio_encoders",
    "ComfyUI/models/model_patches",
    "ComfyUI/models/latent_upscale_models",
    "ComfyUI/input",
    "ComfyUI/output",
    "ComfyUI/custom_nodes",
    "ComfyUI/custom_Workflows"
)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
Write-OK "Directory structure created"

# --- 4b: Clone or update custom nodes ---
Write-Host "  Cloning/updating custom nodes (this may take a few minutes)..." -ForegroundColor Gray

$repositories = @{
    # === SECOURSES Core ===
    "ComfyUI-Manager"              = "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "ComfyUI_IPAdapter_plus"       = "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "ComfyUI-GGUF"                 = "https://github.com/city96/ComfyUI-GGUF.git"
    "RES4LYF"                      = "https://github.com/ClownsharkBatwing/RES4LYF.git"
    "ComfyUI-QuantOps"             = "https://github.com/silveroxides/ComfyUI-QuantOps.git"
    "ComfyUI-Frame-Interpolation"  = "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "ComfyUI-TeaCache"             = "https://github.com/FurkanGozukara/ComfyUI-TeaCache.git"
    "comfyui_controlnet_aux"       = "https://github.com/Fannovel16/comfyui_controlnet_aux.git"

    # === SECOURSES Optional ===
    "ComfyUI-KJNodes"              = "https://github.com/kijai/ComfyUI-KJNodes.git"
    "ComfyUI-Impact-Pack"          = "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "ComfyUI-ReActor"              = "https://github.com/Gourieff/ComfyUI-ReActor.git"
    "ComfyUI-LTXVideo"             = "https://github.com/Lightricks/ComfyUI-LTXVideo.git"
    "ComfyUI-Custom-Scripts"       = "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "rgthree-comfy"                = "https://github.com/rgthree/rgthree-comfy.git"
    "ComfyUI-VideoHelperSuite"     = "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "was-node-suite-comfyui"       = "https://github.com/WASasquatch/was-node-suite-comfyui.git"
    "ComfyUI-MelBandRoFormer"      = "https://github.com/kijai/ComfyUI-MelBandRoFormer.git"
    "ComfyUI-CacheDiT"             = "https://github.com/Jasonzzt/ComfyUI-CacheDiT.git"

    # === Additional Nodes ===
    "ComfyUI-TiledDiffusion"       = "https://github.com/shiimizu/ComfyUI-TiledDiffusion.git"
    "comfyui-easy-use"             = "https://github.com/yolain/comfyui-easy-use.git"
    "ComfyUI-Florence2"            = "https://github.com/kijai/ComfyUI-Florence2.git"
    "comfyui-inspire-pack"         = "https://github.com/ltdrdata/comfyui-inspire-pack.git"
    "comfyui_custom_nodes_alekpet" = "https://github.com/AlekPet/comfyui_custom_nodes_alekpet.git"
    "comfyui_layerstyle"           = "https://github.com/chflame163/ComfyUI_LayerStyle.git"
    "comfyui_lg_tools"             = "https://github.com/LAOGOU-666/Comfyui_LG_Tools.git"
    "ComfyUI-Logic"                = "https://github.com/theUpsider/ComfyUI-Logic.git"
}

$cnRoot = "ComfyUI/custom_nodes"
$cloned = 0; $updated = 0; $failed = 0
foreach ($name in $repositories.Keys) {
    $dest = Join-Path $cnRoot $name
    if (Test-Path (Join-Path $dest ".git")) {
        try {
            git -C $dest pull --rebase 2>&1 | Out-Null
            $updated++
        } catch { $failed++ }
    } else {
        try {
            git clone --depth 1 --recursive $repositories[$name] $dest 2>&1 | Out-Null
            $cloned++
        } catch { $failed++ }
    }
}
Write-OK "Nodes: $cloned cloned, $updated updated, $failed failed"

# --- 4c: Environment file ---
Write-Host ""
if (Test-Path ".env") {
    Write-OK ".env file already exists"
} else {
    Write-Host "  A Hugging Face token is needed to download gated models." -ForegroundColor Yellow
    Write-Host "  Get one at: https://huggingface.co/settings/tokens" -ForegroundColor Yellow
    Write-Host ""
    $hfToken = Read-Host "  Enter your HF token (or press Enter to skip for now)"
    if ($hfToken) {
        "HF_TOKEN=$hfToken" | Set-Content ".env"
        Write-OK "Created .env with HF token"
    } else {
        "HF_TOKEN=" | Set-Content ".env"
        Write-Warn "Created .env without token. Edit .env later to add it."
    }
}

# ================================================================
# STEP 5: BUILD
# ================================================================
Write-Step 5 5 "Build Docker Image"

Write-Host ""
Write-Host "  The Docker image needs to be built before first use." -ForegroundColor White
Write-Host "  This downloads ~8GB and takes 5-15 minutes." -ForegroundColor White
Write-Host ""

if (Ask-YesNo "Build the Docker image now?") {
    Write-Host ""
    Write-Host "  Building... (this will take a while)" -ForegroundColor Gray
    docker compose build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-OK "Build complete!"
    } else {
        Write-Host ""
        Write-Fail "Build failed. Check the output above for errors."
        Read-Host "`n  Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "  Skipped. Run 'run.bat' to build and start later." -ForegroundColor Yellow
}

# ================================================================
# DONE
# ================================================================
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "    Setup Complete!" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Download models (see model list below)" -ForegroundColor White
Write-Host "    2. Run 'run.bat' to start ComfyUI" -ForegroundColor White
Write-Host "    3. Open http://localhost:8188 in your browser" -ForegroundColor White
Write-Host ""
Write-Host "  GPU: $gpuName | Compatibility: $($compatLevel.ToUpper())" -ForegroundColor DarkCyan
if ($compatLevel -eq "partial") {
    Write-Host "  Note: SageAttention auto-disabled for your GPU." -ForegroundColor DarkYellow
    Write-Host "  xFormers attention is used instead. Performance is still good." -ForegroundColor DarkYellow
}
Write-Host ""

# --- Model Download Checklist ---
Write-Host "  --- Recommended Models ---" -ForegroundColor Yellow
Write-Host "  Place downloaded files in the specified folders under ComfyUI\models\"
Write-Host ""
Write-Host "  FLUX.1-dev (diffusion model):" -ForegroundColor White
Write-Host "    https://huggingface.co/black-forest-labs/FLUX.1-dev-bf16" -ForegroundColor Gray
Write-Host "    -> ComfyUI\models\diffusion_models\" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  FLUX VAE (ae.safetensors):" -ForegroundColor White
Write-Host "    https://huggingface.co/black-forest-labs/FLUX.1-dev-bf16" -ForegroundColor Gray
Write-Host "    -> ComfyUI\models\vae\  (rename to flux_ae.safetensors)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Text Encoders (clip_l, t5xxl_fp16):" -ForegroundColor White
Write-Host "    https://huggingface.co/comfyanonymous/flux_text_encoders" -ForegroundColor Gray
Write-Host "    -> ComfyUI\models\text_encoders\" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4x Upscaler:" -ForegroundColor White
Write-Host "    https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth" -ForegroundColor Gray
Write-Host "    -> ComfyUI\models\upscale_models\" -ForegroundColor DarkGray
Write-Host ""

Read-Host "Press Enter to exit"
