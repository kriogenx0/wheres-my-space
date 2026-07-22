.DEFAULT_GOAL := all

PROJECT       := WheresMySpace.xcodeproj
SCHEME        := WheresMySpace
APP_NAME      := WheresMySpace
BUILD_DIR     := build

DEBUG_APP     := $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app
RELEASE_APP   := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app
INSTALLED_APP := /Applications/$(APP_NAME).app

.PHONY: all help setup dev build clean open close install uninstall reinstall

##@ Meta

all: setup dev ## Set up the environment and build+open a dev build (default)

help: ## Show this help, grouped by category
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

##@ Setup

setup: ## Verify the toolchain is ready (no external dependencies to fetch)
	@command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild not found - install Xcode."; exit 1; }
	@echo "No external dependencies. Environment ready."

##@ Build

dev: close ## Build for development (Debug) and open it
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(BUILD_DIR) build
	@open "$(DEBUG_APP)"

build: ## Build for production (Release)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(BUILD_DIR) build

clean: ## Remove build artifacts
	rm -rf $(BUILD_DIR)
	@echo "Cleaned $(BUILD_DIR)/"

##@ Run

open: close build ## Build for production and open it
	@open "$(RELEASE_APP)"

close: ## Quit the running app if it's open
	@if pgrep -x "$(APP_NAME)" >/dev/null; then \
		osascript -e 'tell application "$(APP_NAME)" to quit' >/dev/null 2>&1; \
		sleep 1; \
		pkill -x "$(APP_NAME)" >/dev/null 2>&1 || true; \
		echo "$(APP_NAME) closed."; \
	else \
		echo "$(APP_NAME) is not running."; \
	fi

##@ Install

install: close build ## Build for production and install to /Applications
	rm -rf "$(INSTALLED_APP)"
	cp -R "$(RELEASE_APP)" "$(INSTALLED_APP)"
	@echo "Installed to $(INSTALLED_APP)"

uninstall: close ## Quit the app and remove it from /Applications
	@if [ -d "$(INSTALLED_APP)" ]; then \
		rm -rf "$(INSTALLED_APP)"; \
		echo "Removed $(INSTALLED_APP)"; \
	else \
		echo "$(APP_NAME) is not installed."; \
	fi

reinstall: uninstall install ## Uninstall then install
