APP_NAME := JitterJuice

.PHONY: ipod build run test

ipod:
	@./Tools/ipod.sh

build:
	@xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -configuration Debug -derivedDataPath "$$(pwd)/.derivedData" build

run:
	@open .derivedData/Build/Products/Debug/$(APP_NAME).app

test:
	@xcodebuild test -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -configuration Debug -derivedDataPath "$$(pwd)/.derivedData" -destination 'platform=macOS'

