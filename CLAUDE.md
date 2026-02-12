# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ComfyUI Docker Stack** — Dockerized ComfyUI for AI image/video generation. Runs ComfyUI inside an NVIDIA CUDA 13.0 container with ~50 custom node packages. Based on the SECOURSES V81 setup. Auto-detects GPU compatibility (Turing SM 7.5 through Blackwell).

## Build & Run Commands

```bash
# First-time setup (Windows): checks GPU, clones nodes, creates folders, builds image
install.bat        # Calls install.ps1 — runs compatibility wizard

# Build and start the container
run.bat            # Or: docker compose up --build

# Start without rebuilding
docker compose up

# Stop
docker compose down
```

ComfyUI web UI is available at `http://localhost:8188` once the container is running.

## GPU Compatibility

The entrypoint auto-detects GPU compute capability and adjusts launch flags:
- **SM 8.0+ (Ampere/Ada/Hopper)**: Full — SageAttention + Flash Attention + xFormers
- **SM 7.5 (Turing)**: Partial — xFormers only (SageAttention auto-disabled)
- **SM < 7.5 (Pascal/older)**: Not supported (CUDA 13.0 requirement)

Minimum NVIDIA driver: 570+

## Architecture

### Container Stack

- **Base image**: `nvidia/cuda:13.0.1-devel-ubuntu22.04` with Python 3.10
- **ML runtime**: PyTorch 2.9.1 + CUDA 13.0, prebuilt Flash-Attention 2.8.3, SageAttention 2.2.0, xFormers 0.0.34, InsightFace 0.7.3, Nunchaku 1.2.1, DeepSpeed
- **Package manager**: `uv` (fast pip alternative) used for all installs
- **Startup**: `entrypoint.sh` does a one-time install of custom node deps (flagged by `/app/.custom_nodes_installed_v81`), auto-detects GPU, then launches ComfyUI with appropriate flags

### Volume Mounts (host -> container)

All under `./ComfyUI/` on the host, mapped to `/app/ComfyUI/` in the container:

| Host Path | Purpose |
|-----------|---------|
| `ComfyUI/models/` | ML model files (diffusion_models, vae, text_encoders, controlnet, loras, upscale_models, clip_vision, embeddings, audio_encoders, etc.) |
| `ComfyUI/input/` | Input images/videos for workflows |
| `ComfyUI/output/` | Generated output files |
| `ComfyUI/custom_nodes/` | All custom node packages |
| `ComfyUI/custom_Workflows/` | User and SECOURSES workflow/preset files |

### Key Docker Settings

- **GPU**: Single NVIDIA GPU with compute+utility capabilities
- **Shared memory**: 16 GB (`shm_size: '16gb'`)
- **Environment**: `CUDA_LAUNCH_BLOCKING=0`, `TORCH_USE_CUDA_DSA=1`, `HF_HUB_ENABLE_HF_TRANSFER=1`
- **Restart policy**: `unless-stopped`
- **env_file**: `.env` (contains HuggingFace token)

### Prebuilt Wheels

Flash-Attention, SageAttention, xFormers, InsightFace, and Nunchaku are installed via prebuilt wheels rather than compiled from source. These wheels target PyTorch 2.9.1 + CUDA 13.x + Python 3.10 on Linux x86_64.

### Dependency Version Pins

The entrypoint re-enforces `onnxruntime-gpu==1.22.0` and reinstalls prebuilt wheels after custom node installs. It also upgrades transformers/huggingface_hub after nunchaku (which pins older versions).

### Custom Nodes

~50 custom node packages in `ComfyUI/custom_nodes/`. The `install.ps1` script manages 25+ via git clone; others added via ComfyUI-Manager.

### Pre-built Workflows

`ComfyUI/custom_Workflows/` contains ready-to-use JSON workflow files including SECOURSES presets and workflows.

## Important Notes

- The `.env` file contains a Hugging Face API token. Do not commit it. Use `.env.example` as a template.
- Prebuilt wheels require Python 3.10 on Linux. Do not change the container Python version.
- Deleting `/app/.custom_nodes_installed_v81` inside the container (or rebuilding) re-triggers dependency installation.
- The `SECOURSES_TOOLS/` directory contains the original SECOURSES installation scripts for reference.
