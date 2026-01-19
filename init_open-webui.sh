#!/bin/bash

set -e

echo "Starting Open WebUI Setup..."

echo "To start Open WebUI, you need to provide the OpenAI base URL and API key:"
echo "export OPENAI_API_BASE_URL=<HOST>:<PORT>/v1"
echo "export OPENAI_API_KEY=<API_KEY>"

REQUIRED_VARS=(OPENAI_API_BASE_URL OPENAI_API_KEY)
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Environment variable $var is not set."
        exit 1
    fi
done

CONTAINER_NAME="open-webui-$(date +%s)"

docker run -d \
  -p :8080 \
  -e OPENAI_API_BASE_URL="${OPENAI_API_BASE_URL}" \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  -v open-webui:/app/backend/data \
  --name "$CONTAINER_NAME" \
  ghcr.io/open-webui/open-webui:main