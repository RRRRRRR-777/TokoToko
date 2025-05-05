PRODUCT_NAME := TokoToko

.PHONY: generate-xcodeproj
generate-xcodeproj:
	mint run xcodegen xcodegen generate
	pod install
	make open

.PHONY: open
open:
	open ./${PRODUCT_NAME}.xcworkspace
