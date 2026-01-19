# SGLang Setup Cookbook

This cookbook provides step-by-step instructions for different SGLang deployment scenarios, from single-node testing to high-throughput distributed serving.

## 1. Prerequisites (All Setups)

Before running any of the examples below, you must run the initialization script to install dependencies and the SGLang package.

```bash
# Initialize SGLang environment
source ./init_sglang_git.sh
```

## 2. Single Node Setup

For most development and simple testing, running SGLang on a single node is sufficient.

### Launch Server
```bash
cd sglang && uv run python3 -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --host 0.0.0.0 \
  --port 8000
```

## 3. Distributed Setup (P/D Disaggregation)

This section outlines the steps to enable Prefill-Decode (PD) disaggregation with the Mooncake transfer backend and configure metrics.

### Launching Services (with Metrics)

To enable Grafana/Prometheus integration, add the `--enable-metrics` flag to your worker instances.

#### Terminal 1: Prefill Instance (Port 8001)
```bash
CUDA_VISIBLE_DEVICES=0 uv run python3 -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --disaggregation-mode prefill \
  --port 8001 \
  --host 0.0.0.0 \
  --enable-metrics
```

#### Terminal 2: Decode Instance (Port 8002)
```bash
CUDA_VISIBLE_DEVICES=1 uv run python3 -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --disaggregation-mode decode \
  --port 8002 \
  --host 0.0.0.0 \
  --enable-metrics
```

#### Terminal 3: Router (Port 8000)
The router exposes metrics on port **29000** by default.

```bash
uv run python3 -m sglang_router.launch_router \
  --pd-disaggregation \
  --prefill http://localhost:8001 \
  --decode http://localhost:8002 \
  --host 0.0.0.0 \
  --port 8000
```

### Verification

#### Chat Endpoint
Test the inference API through the router:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 16
  }'
```

#### Metrics Endpoints
Verify that metrics are accessible:

| Component | URL | Note |
|-----------|-----|------|
| **Router** | `http://localhost:29000/metrics` | Enabled by default |
| **Prefill**| `http://localhost:8001/metrics` | Requires `--enable-metrics` |
| **Decode** | `http://localhost:8002/metrics` | Requires `--enable-metrics` |

### Prometheus Configuration
Add this to your `prometheus.yml` to scrape all three components:

```yaml
scrape_configs:
  - job_name: 'sglang_pd'
    static_configs:
      - targets:
        - 'localhost:29000' # Router
        - 'localhost:8001'  # Prefill
        - 'localhost:8002'  # Decode
```
