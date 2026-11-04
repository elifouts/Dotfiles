#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/wofi-paths.sh"
section "Wofi Installer"
ensure_prereqs

install_packages wofi python-pywal16
copy_config_dir "wofi" "wofi"
fix_wofi_paths
apply_default_pywal
fix_wofi_paths
success "Wofi component installed."
