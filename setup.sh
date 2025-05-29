# Script to install dependencies for Codex
#!/usr/bin/env bash
set -e

# Update package lists
apt-get update

# Install basic build tools
apt-get install -y build-essential clang

echo "Setup complete"
