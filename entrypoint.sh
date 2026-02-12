#!/bin/bash
set -e

# ============================================================
# Copy SECOURSES presets/workflows into volume-mounted dirs
# ============================================================
PRESET_DIR="/app/ComfyUI/custom_Workflows/SECOURSES_Presets"
if [ ! -d "$PRESET_DIR" ]; then
    echo "--- Copying SECOURSES presets... ---"
    mkdir -p "$PRESET_DIR"
    cp -r /app/secourses_presets/* "$PRESET_DIR/" 2>/dev/null || true
fi

WORKFLOW_DIR="/app/ComfyUI/custom_Workflows/SECOURSES_Workflows"
if [ ! -d "$WORKFLOW_DIR" ]; then
    echo "--- Copying SECOURSES workflows... ---"
    mkdir -p "$WORKFLOW_DIR"
    cp -r /app/secourses_workflows/* "$WORKFLOW_DIR/" 2>/dev/null || true
fi

DEMO_DIR="/app/ComfyUI/input/SECOURSES_Demo"
if [ ! -d "$DEMO_DIR" ]; then
    echo "--- Copying SECOURSES demo materials... ---"
    mkdir -p "$DEMO_DIR"
    cp -r /app/secourses_demo/* "$DEMO_DIR/" 2>/dev/null || true
fi

# ============================================================
# One-time install for custom node requirements
# ============================================================
if [ ! -f "/app/.custom_nodes_installed_v81" ]; then
    echo "--- Installing custom node requirements (V81 stack)... ---"

    # Install each custom node's requirements using uv
    for req in $(find /app/ComfyUI/custom_nodes -name "requirements.txt" -type f); do
        echo "  Installing: $req"
        uv pip install --system -r "$req" 2>&1 || echo "  WARNING: Failed on $req, continuing..."
    done

    # Run install.py scripts for nodes that have them
    for installer in $(find /app/ComfyUI/custom_nodes -maxdepth 2 -name "install.py" -type f); do
        echo "  Running installer: $installer"
        python "$installer" 2>&1 || echo "  WARNING: Failed on $installer, continuing..."
    done

    # Re-enforce critical version pins after custom node installs
    echo "--- Re-enforcing version pins... ---"
    uv pip install --system "onnxruntime-gpu==1.22.0"

    # Re-install prebuilt wheels in case custom nodes overwrote them
    echo "--- Re-installing prebuilt wheels... ---"
    uv pip install --system \
        https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/flash_attn-2.8.3+torch2.9.1.cuda13.1-cp310-cp310-linux_x86_64.whl \
        https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/sageattention-2.2.0+torch2.9.1.cuda13.1-cp39-abi3-linux_x86_64.whl \
        https://github.com/nunchaku-ai/nunchaku/releases/download/v1.2.1/nunchaku-1.2.1%2Bcu13.0torch2.9-cp310-cp310-linux_x86_64.whl \
        2>/dev/null || true

    # Ensure transformers/huggingface_hub stay at latest (nunchaku pins old versions)
    uv pip install --system "transformers>=5.0" "huggingface_hub>=1.0" 2>/dev/null || true

    touch /app/.custom_nodes_installed_v81
    echo "--- Custom node packages installed (V81 stack). ---"
fi

# ============================================================
# Auto-detect GPU and adjust launch flags
# ============================================================
GPU_SM=$(python3 -c "import torch; cc=torch.cuda.get_device_capability(0); print(cc[0]*10+cc[1])" 2>/dev/null || echo "0")
GPU_NAME=$(python3 -c "import torch; print(torch.cuda.get_device_name(0))" 2>/dev/null || echo "Unknown")
GPU_VRAM=$(python3 -c "import torch; print(f'{torch.cuda.get_device_properties(0).total_memory/1024**3:.1f}GB')" 2>/dev/null || echo "?GB")

echo "--- GPU: $GPU_NAME ($GPU_VRAM) | SM $GPU_SM ---"

# Build launch arguments - strip --use-sage-attention for GPUs below SM 80
LAUNCH_ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--use-sage-attention" ] && [ "$GPU_SM" -lt 80 ]; then
        echo "--- SageAttention disabled (GPU SM${GPU_SM} < SM80). Using xFormers. ---"
        continue
    fi
    LAUNCH_ARGS+=("$arg")
done

if [ "$GPU_SM" -ge 80 ]; then
    echo "--- SageAttention enabled (GPU SM${GPU_SM}) ---"
fi

echo "Starting ComfyUI..."
exec "${LAUNCH_ARGS[@]}"
