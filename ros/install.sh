#!/usr/bin/env bash
set -e

# Check if nix command is available
if ! command -v nix >/dev/null 2>&1; then
  echo "[INFO] Nix not found. Installing Nix..."
  curl -L https://nixos.org/nix/install | sh
  # Load nix profile for current shell
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

nix run .
