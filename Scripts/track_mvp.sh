#!/bin/bash
#
# MVP Tracking Master Script
# Runs all tracking and verification tools to generate comprehensive reports
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Fish Puzzles MVP Tracking System"
echo "===================================="
echo ""

# Check Python availability
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Function to run a tracking script
run_script() {
    local script_name=$1
    local description=$2
    
    echo "📊 $description..."
    if [ -f "$SCRIPT_DIR/$script_name" ]; then
        python3 "$SCRIPT_DIR/$script_name"
        echo "✅ $description complete"
    else
        echo "⚠️  Script not found: $script_name"
    fi
    echo ""
}

# Main tracking workflow
cd "$PROJECT_ROOT"

# 1. Run main MVP tracker with verification
run_script "mvp_tracker.py" "Running MVP verification and progress calculation"

# 2. Run quality verifier for detailed analysis
run_script "mvp_verifier.py" "Analyzing code quality and dependencies"

# 3. Check build status
echo "🔨 Checking build status..."
if make build 2>/dev/null; then
    echo "✅ Build successful"
else
    echo "❌ Build failed - check CharacterAnimationComponent.swift"
fi
echo ""

# 4. Generate summary report
echo "📝 Generating summary report..."
cat > "$PROJECT_ROOT/MVP_SUMMARY.md" << EOF
# MVP Status Summary

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Quick Stats

### Files Generated
- ✅ MVP_VERIFICATION_REPORT.md - Detailed verification results
- ✅ MVP_QUALITY_REPORT.md - Code quality analysis
- ✅ MVP_DASHBOARD.md - Executive dashboard
- ✅ MVP_CHECKLIST.md - Implementation checklist

### Key Metrics
EOF

# Extract key metrics from reports
if [ -f "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" ]; then
    echo "" >> "$PROJECT_ROOT/MVP_SUMMARY.md"
    grep "Overall MVP Progress:" "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" >> "$PROJECT_ROOT/MVP_SUMMARY.md" 2>/dev/null || true
fi

if [ -f "$PROJECT_ROOT/MVP_QUALITY_REPORT.md" ]; then
    grep "Overall Quality Score:" "$PROJECT_ROOT/MVP_QUALITY_REPORT.md" >> "$PROJECT_ROOT/MVP_SUMMARY.md" 2>/dev/null || true
fi

cat >> "$PROJECT_ROOT/MVP_SUMMARY.md" << EOF

## Next Steps

1. Review critical blockers in MVP_VERIFICATION_REPORT.md
2. Check dependency graph in MVP_QUALITY_REPORT.md
3. Update task completion in MVP_CHECKLIST.md
4. Monitor progress in MVP_DASHBOARD.md

## Running This Tracker

\`\`\`bash
# Run full tracking suite
./Scripts/track_mvp.sh

# Run individual components
python3 Scripts/mvp_tracker.py      # Verification and progress
python3 Scripts/mvp_verifier.py     # Quality analysis
\`\`\`

---

*For detailed information, see the individual report files.*
EOF

echo "✅ Summary saved to MVP_SUMMARY.md"
echo ""

# 5. Display final summary
echo "📊 TRACKING COMPLETE"
echo "==================="
echo ""
echo "Reports generated:"
echo "  • MVP_VERIFICATION_REPORT.md - Implementation status"
echo "  • MVP_QUALITY_REPORT.md - Code quality metrics"
echo "  • MVP_DASHBOARD.md - Quick overview"
echo "  • MVP_SUMMARY.md - This run's summary"
echo ""

# Try to extract overall progress
if [ -f "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" ]; then
    PROGRESS=$(grep "Overall MVP Progress:" "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" 2>/dev/null | head -1 || echo "Progress: Unknown")
    echo "🎯 $PROGRESS"
fi

# Count blockers
if [ -f "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" ]; then
    BLOCKERS=$(grep -c "^- \*\*" "$PROJECT_ROOT/MVP_VERIFICATION_REPORT.md" 2>/dev/null || echo "0")
    if [ "$BLOCKERS" -gt 0 ]; then
        echo "⚠️  Found $BLOCKERS critical blockers"
    fi
fi

echo ""
echo "Run 'make build' to verify compilation status."
echo "Run 'make test' to execute test suite."