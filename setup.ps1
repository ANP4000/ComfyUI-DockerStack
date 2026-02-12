#Requires -Version 5.1
$ErrorActionPreference = "Stop"
Write-Host "Starting ComfyUI V81 Content Setup..." -ForegroundColor Green

# --- Part 1: Check for Docker ---
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "Docker is not installed or not on your system's PATH. Please install Docker Desktop and restart your terminal."
}

# --- Part 2: Create local directory structure ---
Write-Host "`nCreating folder structure inside './ComfyUI'..."
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

# --- Part 3: Clone or update all custom nodes ---
Write-Host "`nCloning and updating custom nodes..."
$repositories = @{
  # === SECOURSES Core (always installed) ===
  "ComfyUI-Manager"              = "https://github.com/ltdrdata/ComfyUI-Manager.git"
  "ComfyUI_IPAdapter_plus"       = "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
  "ComfyUI-GGUF"                 = "https://github.com/city96/ComfyUI-GGUF.git"
  "RES4LYF"                      = "https://github.com/ClownsharkBatwing/RES4LYF.git"
  "ComfyUI-QuantOps"             = "https://github.com/silveroxides/ComfyUI-QuantOps.git"
  "ComfyUI-Frame-Interpolation"  = "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
  "ComfyUI-TeaCache"             = "https://github.com/FurkanGozukara/ComfyUI-TeaCache.git"
  "comfyui_controlnet_aux"       = "https://github.com/Fannovel16/comfyui_controlnet_aux.git"

  # === SECOURSES Optional (all included) ===
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

  # === User's Existing Nodes (not in SECOURSES) ===
  "ComfyUI-NAG"                  = "https://github.com/ChenDarYen/ComfyUI-NAG.git"
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
foreach ($name in $repositories.Keys) {
  $dest = Join-Path $cnRoot $name
  if (Test-Path (Join-Path $dest ".git")) {
    Write-Host "   Updating $name..."
    git -C $dest pull --rebase 2>&1 | Out-Null
  } else {
    Write-Host "   Cloning $name..."
    git clone --depth 1 --recursive $repositories[$name] $dest 2>&1 | Out-Null
  }
}

# --- Part 4: Manual Model Download Checklist ---
Write-Host "`n--- Manual Model Download Checklist ---" -ForegroundColor Yellow
Write-Host "Download each file and place it in the specified 'Location' folder."
Write-Host "You can also use the SECOURSES SwarmUI Model Downloader for bulk downloads."

Write-Host "`n--- FLUX Models ---"
Write-Host "1. FLUX.1-dev-bf16"
Write-Host "   Link: https://huggingface.co/black-forest-labs/FLUX.1-dev-bf16/resolve/main/FLUX.1-dev-bf16.safetensors"
Write-Host "   Location: ComfyUI\models\diffusion_models"
Write-Host "2. FLUX AE (VAE)"
Write-Host "   Link: https://huggingface.co/black-forest-labs/FLUX.1-dev-bf16/resolve/main/ae.safetensors"
Write-Host "   Location: ComfyUI\models\vae"
Write-Host "   Save As: flux_ae.safetensors"

Write-Host "`n--- Text Encoders ---"
Write-Host "1. clip_l"
Write-Host "   Link: https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
Write-Host "   Location: ComfyUI\models\text_encoders"
Write-Host "2. t5xxl_fp16"
Write-Host "   Link: https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
Write-Host "   Location: ComfyUI\models\text_encoders"
Write-Host "3. t5xxl_fp8"
Write-Host "   Link: https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn_scaled.safetensors"
Write-Host "   Location: ComfyUI\models\text_encoders"

Write-Host "`n--- Upscale Models ---"
Write-Host "1. 4x NMKD-Siax"
Write-Host "   Link: https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth"
Write-Host "   Location: ComfyUI\models\upscale_models"

Read-Host "`nPress Enter to continue once you have downloaded the required files..."

Write-Host "`nAll folders and nodes are set up!" -ForegroundColor Green
Write-Host "You can now run run.bat to start ComfyUI."
