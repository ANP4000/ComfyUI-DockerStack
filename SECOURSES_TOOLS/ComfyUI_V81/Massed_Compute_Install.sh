#!/bin/bash

export UV_SKIP_WHEEL_FILENAME_CHECK=1
export UV_LINK_MODE=copy

# ========================================
# Optional Custom Nodes / Bundles selection
# Keep IDs aligned with Windows_Custom_Nodes_Bundles_Installer.bat
# Sync plan:
#  - Keep: menu IDs/text + mark_selection() bundle mapping
#  - Keep: git clone URLs and setup blocks in the same numeric order
# ========================================
install_swarm=0
install_kjnodes=0
install_impact=0
install_reactor=0
install_ltxvideo=0
install_customscripts=0
install_rgthree=0
install_videohelper=0
install_wasnodes=0
install_melbandroformer=0
install_cachedit=0

mark_selection() {
    case "$1" in
        1) install_swarm=1 ;;
        2) install_kjnodes=1 ;;
        3) install_impact=1 ;;
        4) install_reactor=1 ;;
        5) install_ltxvideo=1 ;;
        6) install_customscripts=1 ;;
        7) install_rgthree=1 ;;
        8) install_videohelper=1 ;;
        9) install_wasnodes=1 ;;
        10) install_melbandroformer=1 ;;
        11) install_cachedit=1 ;;
        100)
            echo "Activating LTX Audio to Video Bundle..."
            install_kjnodes=1
            install_ltxvideo=1
            install_customscripts=1
            install_rgthree=1
            install_videohelper=1
            install_wasnodes=1
            install_melbandroformer=1
            ;;
        *)
            ;;
    esac
}

parse_and_apply_selection() {
    local input="$1"

    input="${input,,}"

    local trimmed="${input//[[:space:]]/}"
    if [ -z "$trimmed" ] || [ "$trimmed" = "0" ]; then
        return 0
    fi

    if [ "$trimmed" = "all" ] || [ "$trimmed" = "a" ]; then
        input="1,2,3,4,5,6,7,8,9,10,11"
    fi

    input="${input//,/ }"
    input="${input// - /-}"
    input="${input// -/-}"
    input="${input//- /-}"

    local token start end i
    for token in $input; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            if [ "$start" -le "$end" ]; then
                for ((i=start; i<=end; i++)); do
                    mark_selection "$i"
                done
            else
                for ((i=start; i>=end; i--)); do
                    mark_selection "$i"
                done
            fi
        else
            mark_selection "$token"
        fi
    done
}

install_swarm_extranodes() {
    echo ""
    echo "========================================================"
    echo "Installing SwarmUI ExtraNodes (SwarmComfyCommon & SwarmComfyExtra)"
    echo "========================================================"

    if [ -d "SwarmUI" ]; then
        rm -rf SwarmUI
    fi

    if [ -d "SwarmComfyCommon" ]; then
        echo "Removing existing SwarmComfyCommon..."
        rm -rf SwarmComfyCommon
    fi
    if [ -d "SwarmComfyExtra" ]; then
        echo "Removing existing SwarmComfyExtra..."
        rm -rf SwarmComfyExtra
    fi

    echo "Downloading SwarmUI ExtraNodes..."
    git clone --depth 1 --filter=blob:none --sparse https://github.com/mcmonkeyprojects/SwarmUI
    cd SwarmUI || exit 1

    git sparse-checkout set --no-cone \
      src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon \
      src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyExtra

    git checkout

    if [ ! -d "src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon" ]; then
        echo "Error: SwarmComfyCommon directory not found after checkout"
        exit 1
    fi

    cp -r src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon ../SwarmComfyCommon
    cp -r src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyExtra ../SwarmComfyExtra

    cd .. || exit 1
    rm -rf SwarmUI

    echo "SwarmUI ExtraNodes installed successfully."
}

echo "========================================"
echo "ComfyUI Custom Nodes / Bundles Installer (Massed Compute)"
echo "========================================"
echo ""
echo "INDIVIDUAL NODES:"
echo "  1. SwarmUI ExtraNodes (SwarmComfyCommon & SwarmComfyExtra)"
echo "  2. ComfyUI-KJNodes (Kijai)"
echo "  3. ComfyUI-Impact-Pack"
echo "  4. ComfyUI-ReActor (with Impact-Pack dependency)"
echo "  5. ComfyUI-LTXVideo (Lightricks)"
echo "  6. ComfyUI-Custom-Scripts (pythongosssss)"
echo "  7. rgthree-comfy"
echo "  8. ComfyUI-VideoHelperSuite"
echo "  9. WAS Node Suite"
echo " 10. ComfyUI-MelBandRoFormer"
echo " 11. ComfyUI-CacheDiT"
echo ""
echo "BUNDLES:"
echo " 100. LTX Audio to Video Bundle"
echo "      (Includes: KJNodes + LTXVideo + Custom-Scripts + rgthree +"
echo "       VideoHelperSuite + WAS Nodes + MelBandRoFormer)"
echo ""
echo "Selection Options:"
echo "  - Single: 1"
echo "  - Multiple: 1,2,3 or 1 2 3"
echo "  - Range: 1-3 or 5-7"
echo "  - Mixed: 1,3-5,7 or 1 3-5 7"
echo "  - Bundle: 100"
echo "  - All individual nodes: 'all' or 'a'"
echo ""
read -r -p "Enter your selection (Enter/0 to skip): " user_input
parse_and_apply_selection "$user_input"

echo ""
echo "========================================"
echo "Selected nodes to install:"
echo "========================================"
selected_any=0
if [ "$install_swarm" -eq 1 ]; then echo "  [X] SwarmUI ExtraNodes"; selected_any=1; fi
if [ "$install_kjnodes" -eq 1 ]; then echo "  [X] ComfyUI-KJNodes"; selected_any=1; fi
if [ "$install_impact" -eq 1 ]; then echo "  [X] ComfyUI-Impact-Pack"; selected_any=1; fi
if [ "$install_reactor" -eq 1 ]; then echo "  [X] ComfyUI-ReActor"; selected_any=1; fi
if [ "$install_ltxvideo" -eq 1 ]; then echo "  [X] ComfyUI-LTXVideo"; selected_any=1; fi
if [ "$install_customscripts" -eq 1 ]; then echo "  [X] ComfyUI-Custom-Scripts"; selected_any=1; fi
if [ "$install_rgthree" -eq 1 ]; then echo "  [X] rgthree-comfy"; selected_any=1; fi
if [ "$install_videohelper" -eq 1 ]; then echo "  [X] ComfyUI-VideoHelperSuite"; selected_any=1; fi
if [ "$install_wasnodes" -eq 1 ]; then echo "  [X] WAS Node Suite"; selected_any=1; fi
if [ "$install_melbandroformer" -eq 1 ]; then echo "  [X] ComfyUI-MelBandRoFormer"; selected_any=1; fi
if [ "$install_cachedit" -eq 1 ]; then echo "  [X] ComfyUI-CacheDiT"; selected_any=1; fi
if [ "$selected_any" -eq 0 ]; then echo "  (none)"; fi
echo "========================================"
echo ""

read -r -p "Proceed with installation? (Y/N, default Y): " confirm
if [ "${confirm,,}" = "n" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "Starting installation..."
echo ""

mkdir -p ~/.config/pip
cat > ~/.config/pip/pip.conf << 'EOF'
[global]
index-url = https://mcache-kci.massedcompute.com/simple
extra-index-url = https://pypi.org/simple
EOF

git clone --depth 1 https://github.com/Comfy-Org/ComfyUI

cd ComfyUI

git reset --hard

git stash

git pull --force

# Check Python 3.10 availability and install if necessary
echo "Checking Python 3.10 availability..."

PYTHON_CMD=""

# Check if default python3 is Python 3.10
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
    if [ "$PYTHON_VERSION" = "3.10" ]; then
        echo "Default python3 is Python 3.10"
        PYTHON_CMD="python3"
    fi
fi

# If default python3 is not 3.10, check if python3.10 exists
if [ -z "$PYTHON_CMD" ]; then
    if command -v python3.10 &> /dev/null; then
        echo "Found python3.10 command"
        PYTHON_CMD="python3.10"
    fi
fi

# If both checks fail, install Python 3.10
if [ -z "$PYTHON_CMD" ]; then
    echo "Python 3.10 not found. Installing Python 3.10..."
    sudo apt update
    sudo apt install -y python3.10 python3.10-venv python3.10-dev

    # Verify installation
    if command -v python3.10 &> /dev/null; then
        echo "Python 3.10 installed successfully"
        PYTHON_CMD="python3.10"
    else
        echo "Failed to install Python 3.10. Exiting..."
        exit 1
    fi
fi

# Create virtual environment with Python 3.10
echo "Creating virtual environment with $PYTHON_CMD..."
$PYTHON_CMD -m venv venv

source venv/bin/activate

python3 -m pip install --upgrade pip

pip install uv

uv pip install torch==2.9.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

cd custom_nodes

git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager

git clone --depth 1 https://github.com/silveroxides/ComfyUI-QuantOps

cd ComfyUI-QuantOps

git reset --hard

git pull

cd ..

git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation

git clone --depth 1 https://github.com/FurkanGozukara/ComfyUI-TeaCache

git clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux

cd ComfyUI-TeaCache
git remote set-url origin https://github.com/FurkanGozukara/ComfyUI-TeaCache
git stash
git reset --hard
git pull --force
cd ..

# Optional custom nodes selected at the start of the script
if [ "$install_kjnodes" -eq 1 ]; then
    echo "Installing ComfyUI-KJNodes..."
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes
fi

# Clone and install ComfyUI-Impact-Pack
if [ "$install_impact" -eq 1 ]; then
    echo "Installing ComfyUI-Impact-Pack..."
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack
fi

# Clone and install ComfyUI-ReActor
if [ "$install_reactor" -eq 1 ]; then
    echo "Installing ComfyUI-ReActor..."
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor
fi

# Clone ComfyUI-LTXVideo
if [ "$install_ltxvideo" -eq 1 ]; then
    echo "Installing ComfyUI-LTXVideo..."
    git clone --depth 1 https://github.com/Lightricks/ComfyUI-LTXVideo
fi

# Clone ComfyUI-Custom-Scripts
if [ "$install_customscripts" -eq 1 ]; then
    echo "Installing ComfyUI-Custom-Scripts..."
    git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts
fi

# Clone rgthree-comfy
if [ "$install_rgthree" -eq 1 ]; then
    echo "Installing rgthree-comfy..."
    git clone --depth 1 https://github.com/rgthree/rgthree-comfy
fi

# Clone ComfyUI-VideoHelperSuite
if [ "$install_videohelper" -eq 1 ]; then
    echo "Installing ComfyUI-VideoHelperSuite..."
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
fi

# Clone WAS Node Suite
if [ "$install_wasnodes" -eq 1 ]; then
    echo "Installing WAS Node Suite..."
    git clone --depth 1 https://github.com/ltdrdata/was-node-suite-comfyui
fi

# Clone ComfyUI-MelBandRoFormer
if [ "$install_melbandroformer" -eq 1 ]; then
    echo "Installing ComfyUI-MelBandRoFormer..."
    git clone --depth 1 https://github.com/kijai/ComfyUI-MelBandRoFormer
fi

# Clone ComfyUI-CacheDiT
if [ "$install_cachedit" -eq 1 ]; then
    echo "Installing ComfyUI-CacheDiT..."
    git clone --depth 1 https://github.com/Jasonzzt/ComfyUI-CacheDiT
fi

# Clone ComfyUI-GGUF
git clone --depth 1 https://github.com/city96/ComfyUI-GGUF

# Clone RES4LYF
git clone --depth 1 https://github.com/ClownsharkBatwing/RES4LYF

# Setup ComfyUI-Manager
cd ComfyUI-Manager
git stash
git reset --hard
git pull --force
uv pip install -r requirements.txt
cd ..

# Setup ComfyUI-KJNodes
if [ "$install_kjnodes" -eq 1 ]; then
    echo "Setting up ComfyUI-KJNodes..."
    cd ComfyUI-KJNodes
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-ReActor
if [ "$install_reactor" -eq 1 ]; then
    echo "Setting up ComfyUI-ReActor (this may take a while)..."

    # Install Impact-Pack dependency if not already installed
    if [ ! -d "ComfyUI-Impact-Pack" ]; then
        echo "Installing ComfyUI-Impact-Pack dependency for ReActor..."
        git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack
        cd ComfyUI-Impact-Pack
        git stash
        git reset --hard
        git pull --force
        if [ -f install.py ]; then python install.py; fi
        if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
        cd ..
    fi

    cd ComfyUI-ReActor
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-GGUF
cd ComfyUI-GGUF
git stash
git reset --hard
git pull --force
uv pip install -r requirements.txt
cd ..

# Setup ComfyUI-Impact-Pack
if [ "$install_impact" -eq 1 ]; then
    echo "Setting up ComfyUI-Impact-Pack..."
    cd ComfyUI-Impact-Pack
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-LTXVideo
if [ "$install_ltxvideo" -eq 1 ]; then
    echo "Setting up ComfyUI-LTXVideo..."
    cd ComfyUI-LTXVideo
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-Custom-Scripts
if [ "$install_customscripts" -eq 1 ]; then
    echo "Setting up ComfyUI-Custom-Scripts..."
    cd ComfyUI-Custom-Scripts
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup rgthree-comfy
if [ "$install_rgthree" -eq 1 ]; then
    echo "Setting up rgthree-comfy..."
    cd rgthree-comfy
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-VideoHelperSuite
if [ "$install_videohelper" -eq 1 ]; then
    echo "Setting up ComfyUI-VideoHelperSuite..."
    cd ComfyUI-VideoHelperSuite
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup WAS Node Suite
if [ "$install_wasnodes" -eq 1 ]; then
    echo "Setting up WAS Node Suite..."
    cd was-node-suite-comfyui
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-MelBandRoFormer
if [ "$install_melbandroformer" -eq 1 ]; then
    echo "Setting up ComfyUI-MelBandRoFormer..."
    cd ComfyUI-MelBandRoFormer
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Setup ComfyUI-CacheDiT
if [ "$install_cachedit" -eq 1 ]; then
    echo "Setting up ComfyUI-CacheDiT..."
    cd ComfyUI-CacheDiT
    git stash
    git reset --hard
    git pull --force
    if [ -f install.py ]; then python install.py; fi
    if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
    cd ..
fi

# Install SwarmUI ExtraNodes (copy into custom_nodes)
if [ "$install_swarm" -eq 1 ]; then
    install_swarm_extranodes
fi

# Setup RES4LYF
cd RES4LYF
git stash
git reset --hard
git pull --force
uv pip install -r requirements.txt
cd ..





cd ..

echo Installing ComfyUI requirements...

uv pip install -r requirements.txt

pip uninstall xformers -y

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/flash_attn-2.8.3+torch2.9.1.cuda13.1-cp310-cp310-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/xformers-0.0.34+41531cee.d20260109-cp39-abi3-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/sageattention-2.2.0+torch2.9.1.cuda13.1-cp39-abi3-linux_x86_64.whl

uv pip install https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main/insightface-0.7.3-cp310-cp310-linux_x86_64.whl

uv pip install deepspeed

cd ..

echo Installing Shared requirements...

uv pip install -r requirements_Comfy.txt

sudo apt update

sudo apt install psmisc

sudo snap install ngrok

echo ""
echo "Installation complete!"
