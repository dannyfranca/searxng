# SearXNG Quadlet Installation Makefile
# 
# This Makefile helps install Quadlet files for running SearXNG
# as a systemd-managed Podman container.

SHELL := /bin/bash

# Quadlet directories (settings go in a subdirectory alongside quadlet files)
QUADLET_USER_DIR := $(HOME)/.config/containers/systemd
QUADLET_SYSTEM_DIR := /etc/containers/systemd
SETTINGS_USER_DIR := $(QUADLET_USER_DIR)/searxng
SETTINGS_SYSTEM_DIR := $(QUADLET_SYSTEM_DIR)/searxng

.PHONY: help install-user install-system uninstall-user uninstall-system reload generate-secret start stop status logs

help:
	@echo "SearXNG Quadlet Installation"
	@echo ""
	@echo "Available targets:"
	@echo "  install-user    - Install quadlet + settings for current user (rootless)"
	@echo "  install-system  - Install quadlet + settings system-wide (requires root)"
	@echo "  uninstall-user  - Remove all files from user directory"
	@echo "  uninstall-system- Remove all files from system directory"
	@echo "  reload          - Reload systemd daemon to recognize new units"
	@echo "  generate-secret - Generate a random secret key for SearXNG"
	@echo "  start           - Start the SearXNG service (user mode)"
	@echo "  stop            - Stop the SearXNG service (user mode)"
	@echo "  status          - Check SearXNG service status"
	@echo "  logs            - View SearXNG logs"
	@echo ""
	@echo "Quick start (rootless/user mode):"
	@echo "  1. make install-user"
	@echo "  2. make generate-secret"
	@echo "  3. Edit $(QUADLET_USER_DIR)/searxng.container (set SEARXNG_SECRET)"
	@echo "  4. Optionally edit $(SETTINGS_USER_DIR)/settings.yml"
	@echo "  5. make reload"
	@echo "  6. make start"

# Generate a random secret key
generate-secret:
	@echo "Generated secret key:"
	@echo ""
	@openssl rand -hex 32
	@echo ""
	@echo "Add this to your searxng.container file as:"
	@echo "  Environment=SEARXNG_SECRET=<key>"

# Install for current user (rootless podman)
install-user:
	@mkdir -p $(QUADLET_USER_DIR)
	@mkdir -p $(SETTINGS_USER_DIR)
	@cp quadlet/searxng.container $(QUADLET_USER_DIR)/
	@cp searxng/settings.yml $(SETTINGS_USER_DIR)/
	@echo ""
	@echo "Installed to $(QUADLET_USER_DIR):"
	@echo "  - searxng.container"
	@echo "  - searxng/settings.yml"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run: make generate-secret"
	@echo "  2. Edit: $(QUADLET_USER_DIR)/searxng.container"
	@echo "     Set SEARXNG_SECRET=<your-generated-key>"
	@echo "  3. Run: make reload && make start"

# Install system-wide (requires root)
install-system:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Error: This target requires root privileges. Run with sudo."; \
		exit 1; \
	fi
	@mkdir -p $(QUADLET_SYSTEM_DIR)
	@mkdir -p $(SETTINGS_SYSTEM_DIR)
	@cp quadlet/searxng.container $(QUADLET_SYSTEM_DIR)/
	@cp searxng/settings.yml $(SETTINGS_SYSTEM_DIR)/
	@echo ""
	@echo "Installed to $(QUADLET_SYSTEM_DIR):"
	@echo "  - searxng.container"
	@echo "  - searxng/settings.yml"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Generate secret: openssl rand -hex 32"
	@echo "  2. Edit: $(QUADLET_SYSTEM_DIR)/searxng.container"
	@echo "  3. Run: systemctl daemon-reload && systemctl start searxng"

# Uninstall from user directory
uninstall-user:
	@rm -f $(QUADLET_USER_DIR)/searxng.container
	@rm -rf $(SETTINGS_USER_DIR)
	@echo "SearXNG files removed from $(QUADLET_USER_DIR)"

# Uninstall from system directory
uninstall-system:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Error: This target requires root privileges. Run with sudo."; \
		exit 1; \
	fi
	@rm -f $(QUADLET_SYSTEM_DIR)/searxng.container
	@rm -rf $(SETTINGS_SYSTEM_DIR)
	@echo "SearXNG files removed from $(QUADLET_SYSTEM_DIR)"

# Reload systemd to recognize new quadlet units
reload:
	@systemctl --user daemon-reload
	@echo "Systemd daemon reloaded"
	@echo "Generated units:"
	@systemctl --user list-unit-files | grep searxng || echo "  (units may need a moment to appear)"

# Start the service
start:
	@systemctl --user start searxng.service
	@echo "SearXNG started. Access at http://localhost:8888"

# Stop the service
stop:
	@systemctl --user stop searxng.service
	@echo "SearXNG stopped"

# Check status
status:
	@systemctl --user status searxng.service

# View logs
logs:
	@journalctl --user -u searxng.service -f
