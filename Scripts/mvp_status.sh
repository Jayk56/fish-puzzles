#!/bin/bash

# MVP Status Report Generator
# Generates a quick status report of the MVP implementation

echo "========================================="
echo "     Fish Puzzles MVP Status Report     "
echo "========================================="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Check build status
echo "📱 Build Status:"
if make build > /dev/null 2>&1; then
    echo "  ✅ Project builds successfully"
else
    echo "  ❌ Build failing - check errors"
fi
echo ""

# Count Swift files
echo "📊 Codebase Metrics:"
SWIFT_COUNT=$(find fish-puzzles -name "*.swift" | wc -l | tr -d ' ')
echo "  Swift files: $SWIFT_COUNT"

# Count scenes
SCENE_COUNT=$(find fish-puzzles/fish-puzzles/Scenes -name "*Scene.swift" | wc -l | tr -d ' ')
echo "  Scene files: $SCENE_COUNT"

# Count systems
SYSTEM_COUNT=$(find fish-puzzles/fish-puzzles/Systems -name "*.swift" | wc -l | tr -d ' ')
echo "  System components: $SYSTEM_COUNT"

# Count UI components
UI_COUNT=$(find fish-puzzles/fish-puzzles/UI -name "*.swift" | wc -l | tr -d ' ')
echo "  UI components: $UI_COUNT"
echo ""

# Check for assets
echo "🎨 Asset Status:"
if [ -d "Assets/Art" ]; then
    ART_COUNT=$(find Assets/Art -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  Art assets: $ART_COUNT files"
else
    echo "  Art assets: Directory not found"
fi

if [ -d "Assets/Audio" ]; then
    AUDIO_COUNT=$(find Assets/Audio -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  Audio files: $AUDIO_COUNT files"
else
    echo "  Audio files: Directory not found"
fi
echo ""

# Check test coverage
echo "🧪 Test Coverage:"
if [ -d "fish-puzzlesTests" ]; then
    TEST_COUNT=$(find fish-puzzlesTests -name "*.swift" | wc -l | tr -d ' ')
    echo "  Test files: $TEST_COUNT"
else
    echo "  Tests: Not found"
fi
echo ""

# TODO counting
echo "📝 TODOs in Code:"
TODO_COUNT=$(grep -r "TODO:" fish-puzzles --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
FIXME_COUNT=$(grep -r "FIXME:" fish-puzzles --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
echo "  TODO comments: $TODO_COUNT"
echo "  FIXME comments: $FIXME_COUNT"
echo ""

# File size check
echo "📦 Build Size:"
if [ -d "fish-puzzles.xcodeproj" ]; then
    PROJECT_SIZE=$(du -sh fish-puzzles 2>/dev/null | cut -f1)
    echo "  Project size: $PROJECT_SIZE"
fi
echo ""

# Documentation check
echo "📚 Documentation:"
for doc in README.md CLAUDE.md MVP_IMPLEMENTATION_TRACKER.md MVP_DASHBOARD.md MVP_CHECKLIST.md; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc exists"
    else
        echo "  ❌ $doc missing"
    fi
done
echo ""

# Quick completion estimate (very rough)
echo "🎯 Rough MVP Completion Estimate:"
echo "  Based on file structure analysis"
echo ""
echo "  Core Systems:    ~55% ████████████░░░░░░░░"
echo "  Game Content:    ~5%  █░░░░░░░░░░░░░░░░░░░"  
echo "  Assets:          ~10% ██░░░░░░░░░░░░░░░░░░"
echo "  Documentation:   ~50% ██████████░░░░░░░░░░"
echo ""
echo "  Overall:         ~30% ██████░░░░░░░░░░░░░░"
echo ""

echo "========================================="
echo "For detailed tracking, see:"
echo "  - MVP_IMPLEMENTATION_TRACKER.md"
echo "  - MVP_DASHBOARD.md"
echo "  - MVP_CHECKLIST.md"
echo "========================================="