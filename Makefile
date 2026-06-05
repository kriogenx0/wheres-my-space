APP     := WheresMySpace
SCHEME  := WheresMySpace
PROJECT := WheresMySpace.xcodeproj

BUILD       := build
DEV_APP     := $(BUILD)/Build/Products/Debug/$(APP).app
RELEASE_APP := $(BUILD)/Build/Products/Release/$(APP).app
DEST        := $(HOME)/Applications/$(APP).app

.PHONY: build dev run publish install open publish-open clean uninstall

# Build for dev. Don't open.
build:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-derivedDataPath "$(BUILD)" \
		-quiet

# Just run it.
dev run:
	open "$(DEV_APP)"

# Build for production. Don't install.
publish:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-derivedDataPath "$(BUILD)" \
		-quiet

# Build and install into production.
install: publish
	@mkdir -p "$(HOME)/Applications"
	@rm -rf "$(DEST)"
	@cp -r "$(RELEASE_APP)" "$(DEST)"
	@echo "Installed → $(DEST)"

# Open in production. If it doesn't exist, build.
open:
	@test -d "$(DEST)" || $(MAKE) install
	open "$(DEST)"

# Build for production, close if open, uninstall existing, open.
publish-open: publish
	@pkill -x "$(APP)" || true
	@sleep 0.5
	@rm -rf "$(DEST)"
	@mkdir -p "$(HOME)/Applications"
	@cp -r "$(RELEASE_APP)" "$(DEST)"
	open "$(DEST)"

# Clean everything, even cache.
clean:
	rm -rf "$(BUILD)"
	@echo "Cleaned"

uninstall:
	@rm -rf "$(DEST)"
	@echo "Uninstalled $(APP)"
