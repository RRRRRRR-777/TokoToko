PRODUCT_NAME := TokoToko

ifneq (,$(wildcard .env))
	include .env
	export
endif

.PHONY: generate-xcodeproj
generate-xcodeproj:
	mint run xcodegen xcodegen generate
	pod install
	make open

.PHONY: open
open:
	open ./${PRODUCT_NAME}.xcworkspace

.PHONY: xcode-run
xcode-run:
	mint run xcodegen xcodegen generate
	pod install
	xcodebuild \
		-workspace TokoToko.xcworkspace \
		-scheme $(PRODUCT_NAME) \
		-sdk iphonesimulator \
		-destination "platform=iOS Simulator,name=$(DEVICE_NAME),OS=$(OS_VERSION)" \
		-configuration Debug \
		build

	APP_PATH=$$HOME/Library/Developer/Xcode/DerivedData/$(PRODUCT_NAME)-*/Build/Products/Debug-iphonesimulator/$(PRODUCT_NAME).app && \
	xcrun simctl boot "$(DEVICE_NAME)" || true && \
	xcrun simctl install booted $$APP_PATH && \
	xcrun simctl launch booted $(BUNDLE_ID)
	open -a Simulator
