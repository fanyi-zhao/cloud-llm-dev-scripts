#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 0. Validation: Ensure required environment variables are present
REQUIRED_VARS=(AWS_ACCESS_KEY AWS_SECRET_KEY AWS_REGION)
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Environment variable $var is not set."
        exit 1
    fi
done

# 1. Auto-Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    echo "📦 AWS CLI not found. Installing..."
    
    # Update and install unzip/curl
    sudo apt-get update && sudo apt-get install -y unzip curl
    
    # Download and install the official AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    
    # Cleanup installation files
    rm -rf aws awscliv2.zip
    echo "✅ AWS CLI installed successfully."
fi

# 2. Create the .aws directory and config files
mkdir -p ~/.aws

cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_KEY
EOF

cat <<EOF > ~/.aws/config
[default]
region = $AWS_REGION
EOF

# 3. Secure the credential files
chmod 600 ~/.aws/credentials ~/.aws/config

echo "✨ AWS configuration files generated for region: $AWS_REGION"
echo "------------------------------------------------------------"
echo "🚀 Useful Commands:"
echo "List:   aws s3 ls s3://<bucket_name>"
echo "Push:   aws s3 cp <local_path> s3://<bucket_name>/<path> --recursive"
echo "Pull:   aws s3 cp s3://<bucket_name>/<path> <local_path> --recursive"