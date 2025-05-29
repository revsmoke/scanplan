#!/bin/bash
# Setup script to install build dependencies for this project.
# Requires sudo/root privileges.
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

apt-get update
# Install build tools. xcodebuild may not be available on all systems
apt-get install -y build-essential xcodebuild || true

