#!/usr/bin/env bash
set -e

# Install Docker on Debian/Ubuntu based systems
if ! command -v docker &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y docker.io
fi
