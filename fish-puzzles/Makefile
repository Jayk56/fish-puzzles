.PHONY: all setup build test run clean atlases lint format help

all: clean build test

help: ## Show this help message
	@echo "Fish Puzzles - Build Commands"
	@echo ""
	@grep -E "^[a-zA-Z_-]+:.*?## .*$$" $(MAKEFILE_LIST) | sort | awk "BEGIN {FS = \":.*?## \"}; {printf \"\\033[36m%-15s\\033[0m %s\\n\", \$$1, \$$2}"

setup: ## Initial project setup
	@echo "Setting up project..."
	@if ! command -v swiftlint &> /dev/null; then \\
		echo "Installing SwiftLint..."; \\
		brew install swiftlint; \\
	fi
	@if ! command -v xcbeautify &> /dev/null; then \\
		echo "Installing xcbeautify..."; \\
		brew install xcbeautify; \\
	fi
	@echo "✓ Setup complete"

build: ## Build the project
	@echo "Building project..."
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -configuration Debug build | xcbeautify

test: ## Run all tests
	@echo "Running tests..."
	@xcodebuild test -project fish-puzzles.xcodeproj -scheme fish-puzzles -destination "platform=iOS Simulator,name=iPhone 15" | xcbeautify

run: ## Run the app in simulator
	@echo "Running app..."
	@open -a Simulator
	@sleep 2
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -destination "platform=iOS Simulator,name=iPhone 15" -configuration Debug build run | xcbeautify

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@xcodebuild -project fish-puzzles.xcodeproj clean
	@rm -rf .build
	@rm -rf DerivedData
	@rm -rf ../DerivedData
	@rm -rf ../ProcessedAssets

atlases: ## Generate texture atlases
	@echo "Generating texture atlases..."
	@python3 Scripts/generate_atlases.py

lint: ## Run SwiftLint
	@echo "Linting code..."
	@swiftlint

format: ## Format code with SwiftFormat
	@echo "Formatting code..."
	@if command -v swiftformat &> /dev/null; then \\
		swiftformat . --swiftversion 5.9; \\
	else \\
		echo "SwiftFormat not installed. Install with: brew install swiftformat"; \\
	fi

debug: ## Build and run in debug mode
	@echo "Running in debug mode..."
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -configuration Debug -destination "platform=iOS Simulator,name=iPhone 15" build run | xcbeautify

release: ## Build for release
	@echo "Building release..."
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -configuration Release build | xcbeautify

profile: ## Run with performance profiling
	@echo "Running with profiling..."
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -enableCodeCoverage YES -enableAddressSanitizer YES test | xcbeautify

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@xcodebuild test -project fish-puzzles.xcodeproj -scheme fish-puzzles -only-testing:fish-puzzlesTests -destination "platform=iOS Simulator,name=iPhone 15" | xcbeautify

test-ui: ## Run UI tests only
	@echo "Running UI tests..."
	@xcodebuild test -project fish-puzzles.xcodeproj -scheme fish-puzzles -only-testing:fish-puzzlesUITests -destination "platform=iOS Simulator,name=iPhone 15" | xcbeautify

archive: ## Create archive for App Store
	@echo "Creating archive..."
	@xcodebuild -project fish-puzzles.xcodeproj -scheme fish-puzzles -configuration Release -archivePath ./build/fish-puzzles.xcarchive archive | xcbeautify
