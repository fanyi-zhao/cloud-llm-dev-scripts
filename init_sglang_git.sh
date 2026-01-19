#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Initializing sglang git repository..."

# 1. System Dependencies
sudo apt-get update && sudo apt-get install -y libnuma1 git

# 2. Setup pipx & uv
pip install pipx
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
uv pip install -e "python[test]"

echo "✅ Installation complete."
echo "--------------------------------------------------------"
echo "To start the server, run:"
echo "cd sglang && uv run python3 -m sglang.launch_server --model-path meta-llama/Llama-3.1-8B-Instruct --host 0.0.0.0 --port 8000"
echo "--------------------------------------------------------"