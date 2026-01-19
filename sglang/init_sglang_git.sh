#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Initializing sglang git repository..."

# 1. System Dependencies
sudo apt-get update && sudo apt-get install -y libnuma1 git

# 2. Setup pipx & uv
# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "pipx not found, attempting installation..."
    # Try apt first (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        echo "Using apt-get to install pipx..."
        sudo apt-get update && sudo apt-get install -y pipx || {
            echo "apt install failed, falling back to pip..."
            pip install --user pipx || pip install pipx
        }
    else
        # Fallback to pip (other envs)
        echo "apt-get not found, using pip..."
        pip install --user pipx || pip install pipx
    fi
else
    echo "pipx is already installed."
fi
export PATH="$HOME/.local/bin:$PATH"

# Ensure pipx path is set for future login sessions
pipx ensurepath --force

# Install uv via pipx
if ! command -v uv &> /dev/null; then
    pipx install uv
fi

# 3. Clone and Setup Repository
if [ ! -d "sglang" ]; then
    git clone https://github.com/sgl-project/sglang.git
fi
cd sglang

# 4. Virtual Environment Management
# --seed ensures pip is installed in the venv immediately
uv venv
source .venv/bin/activate

echo "Install the package in editable mode with test dependencies..."
# sglang main repo
uv pip install -e "python[test]"
# sglang router
sudo apt-get install -y pkg-config libssl-dev protobuf-compiler
uv pip install -e "sgl-model-gateway/bindings/python[test]"

# SGLang doesn't include the disaggregation transfer backends by default to keep the core package light. mooncake is the recommended backend and supports both RDMA (for clusters) and TCP (for single nodes).
echo "Attempting to install optional dependency for P/D Disaggregation:"
(
    echo "Installing mooncake..."
    sudo apt-get update && sudo apt-get install -y libibverbs1 libibverbs-dev
    uv pip install mooncake-transfer-engine
    echo "Testing mooncake..."
    uv run python3 -c "from mooncake.engine import TransferEngine; print('Mooncake import successful')"
) || echo "Optional dependency mooncake failed to install. Proceeding anyway."

echo "✅ Installation complete."
echo "--------------------------------------------------------"
echo "To start the server, run:"
echo "cd sglang && uv run python3 -m sglang.launch_server --model-path meta-llama/Llama-3.1-8B-Instruct --host 0.0.0.0 --port 8000"
echo "--------------------------------------------------------"