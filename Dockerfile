FROM nvidia/cuda:13.0.1-devel-ubuntu22.04

# ============================================================
# 1. OS dependencies
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential ninja-build ffmpeg libgl1-mesa-glx libglib2.0-0 \
    pkg-config libcairo2-dev python3.10 python3-pip python3.10-dev python3.10-venv \
    wget curl psmisc \
    && rm -rf /var/lib/apt/lists/*

# Make python3.10 the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# ============================================================
# 2. Clone ComfyUI
# ============================================================
WORKDIR /app
RUN git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git
WORKDIR /app/ComfyUI

# ============================================================
# 3. Install uv and upgrade pip
# ============================================================
RUN python -m pip install --upgrade pip && \
    pip install uv

ENV UV_SKIP_WHEEL_FILENAME_CHECK=1
ENV UV_LINK_MODE=copy

# ============================================================
# 4. Install PyTorch 2.9.1 + CUDA 13.0
# ============================================================
RUN uv pip install --system torch==2.9.1 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu130

# ============================================================
# 5. Install ComfyUI's own requirements
# ============================================================
RUN uv pip install --system -r requirements.txt

# ============================================================
# 6. Install prebuilt wheels from HuggingFace
# ============================================================
RUN pip uninstall xformers -y 2>/dev/null; true

# Flash Attention 2.8.3 (cp310 Linux)
RUN uv pip install --system \
    https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/flash_attn-2.8.3+torch2.9.1.cuda13.1-cp310-cp310-linux_x86_64.whl

# xFormers 0.0.34 (cp39-abi3, any Python 3.9+)
RUN uv pip install --system \
    https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/xformers-0.0.34+41531cee.d20260109-cp39-abi3-linux_x86_64.whl

# SageAttention 2.2.0 (cp39-abi3, any Python 3.9+)
RUN uv pip install --system \
    https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/sageattention-2.2.0+torch2.9.1.cuda13.1-cp39-abi3-linux_x86_64.whl

# InsightFace 0.7.3 (cp310 Linux - needed for ReActor/FaceID)
RUN uv pip install --system \
    https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl

# Nunchaku 1.2.1 (4-bit quantized FLUX inference - MIT HAN Lab)
RUN uv pip install --system \
    https://github.com/nunchaku-ai/nunchaku/releases/download/v1.2.1/nunchaku-1.2.1%2Bcu13.0torch2.9-cp310-cp310-linux_x86_64.whl

# DeepSpeed (from PyPI)
RUN uv pip install --system deepspeed

# ============================================================
# 7. Install SECOURSES shared requirements
# ============================================================
COPY requirements_v81.txt /app/requirements_v81.txt
RUN uv pip install --system -r /app/requirements_v81.txt

# ============================================================
# 8. Additional packages for custom nodes
# ============================================================
RUN uv pip install --system \
    bitsandbytes \
    blend-modes PyWavelets scikit-image opencv-python-headless \
    psutil

# ============================================================
# 9. Copy SECOURSES presets, workflows, and demo materials
# ============================================================
COPY SECOURSES_TOOLS/ComfyUI_V81/Presets /app/secourses_presets
COPY SECOURSES_TOOLS/ComfyUI_V81/WorkFlows /app/secourses_workflows
COPY SECOURSES_TOOLS/ComfyUI_V81/Demo_Materials /app/secourses_demo

# ============================================================
# 10. Entrypoint
# ============================================================
COPY entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENV CUDA_HOME=/usr/local/cuda

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--use-sage-attention", "--gpu-only"]
