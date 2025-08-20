#!/usr/bin/env python3
"""
MVP Feature Tracker - Automated verification and progress tracking for Fish Puzzles MVP
Analyzes codebase to verify implementation status and generate tracking reports.
"""

import os
import json
import glob
import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from collections import defaultdict

class MVPTracker:
    def __init__(self, project_root: str = None):
        self.project_root = Path(project_root or os.getcwd())
        self.fish_puzzles_dir = self.project_root / "fish-puzzles"
        self.features_file = self.project_root / "mvp_features.json"
        self.tracker_file = self.project_root / "MVP_IMPLEMENTATION_TRACKER.md"
        self.dashboard_file = self.project_root / "MVP_DASHBOARD.md"
        self.verification_results = {}
        self.blockers = []
        self.dependencies = defaultdict(list)
        
    def load_features_config(self) -> Dict:
        """Load the MVP features configuration from JSON"""
        if self.features_file.exists():
            with open(self.features_file, 'r') as f:
                return json.load(f)
        return {}
    
    def save_features_config(self, config: Dict):
        """Save updated features configuration"""
        with open(self.features_file, 'w') as f:
            json.dump(config, f, indent=2)
    
    # ===== VERIFICATION FUNCTIONS =====
    
    def verify_scene_files(self) -> Tuple[int, int, List[str]]:
        """Verify scene implementation status"""
        scenes_dir = self.fish_puzzles_dir / "Scenes"
        implemented = []
        
        # Check for actual scene implementations
        scene_patterns = [
            "MainMenu/MainMenuScene.swift",
            "Location1/Location1Scene.swift", 
            "Location2/Location2Scene.swift"
        ]
        
        for pattern in scene_patterns:
            full_path = scenes_dir / pattern
            if full_path.exists():
                # Check if scene has actual content
                with open(full_path, 'r') as f:
                    content = f.read()
                    if "class" in content and "SKScene" in content:
                        implemented.append(str(full_path.relative_to(self.project_root)))
        
        required = 3  # MainMenu + 2 locations
        return len(implemented), required, implemented
    
    def verify_puzzle_system(self) -> Tuple[int, int, List[str]]:
        """Verify puzzle implementation"""
        puzzles_found = []
        puzzle_dir = self.fish_puzzles_dir / "Puzzles"
        
        if puzzle_dir.exists():
            # Look for puzzle class files
            for puzzle_file in puzzle_dir.glob("**/*.swift"):
                with open(puzzle_file, 'r') as f:
                    content = f.read()
                    if "Puzzle" in content and "class" in content:
                        puzzles_found.append(str(puzzle_file.relative_to(self.project_root)))
        
        required = 8  # 6-8 puzzles required
        return len(puzzles_found), required, puzzles_found
    
    def verify_character_assets(self) -> Tuple[int, int, List[str]]:
        """Verify character assets and sprites"""
        characters = []
        assets_dir = self.fish_puzzles_dir / "Assets.xcassets"
        
        if assets_dir.exists():
            # Check for sprite atlases
            for atlas in assets_dir.glob("*.spriteatlas"):
                characters.append(str(atlas.relative_to(self.project_root)))
            
            # Check processed assets
            processed = self.project_root / "ProcessedAssets"
            if processed.exists():
                for char_asset in processed.glob("*Character*"):
                    characters.append(str(char_asset.relative_to(self.project_root)))
        
        required = 12  # 10-12 characters
        return len(characters), required, characters
    
    def verify_background_assets(self) -> Tuple[int, int, List[str]]:
        """Verify background art assets"""
        backgrounds = []
        
        # Check multiple possible locations
        asset_locations = [
            self.fish_puzzles_dir / "Assets.xcassets",
            self.project_root / "Assets" / "Art" / "Backgrounds",
            self.project_root / "ProcessedAssets" / "Backgrounds"
        ]
        
        for location in asset_locations:
            if location.exists():
                for bg in location.glob("*Background*"):
                    backgrounds.append(str(bg.relative_to(self.project_root)))
        
        required = 6
        return len(backgrounds), required, backgrounds
    
    def verify_audio_system(self) -> Dict[str, Tuple[int, int, List[str]]]:
        """Verify audio assets and system"""
        results = {}
        
        # Check audio manager implementation
        audio_manager = self.fish_puzzles_dir / "Systems" / "Audio" / "AudioManager.swift"
        if audio_manager.exists():
            results["system"] = (1, 1, [str(audio_manager.relative_to(self.project_root))])
        else:
            results["system"] = (0, 1, [])
        
        # Check for audio assets
        audio_dir = self.project_root / "Assets" / "Audio"
        
        # Music tracks
        music_files = []
        if audio_dir.exists():
            music_files = list((audio_dir / "Music").glob("*.m4a")) if (audio_dir / "Music").exists() else []
        results["music"] = (len(music_files), 2, [str(f.relative_to(self.project_root)) for f in music_files])
        
        # Voice over
        vo_files = []
        if audio_dir.exists() and (audio_dir / "VO").exists():
            vo_files = list((audio_dir / "VO").glob("*.m4a"))
        results["voice_over"] = (len(vo_files), 100, [str(f.relative_to(self.project_root)) for f in vo_files[:5]])  # Sample first 5
        
        # Sound effects
        sfx_files = []
        if audio_dir.exists() and (audio_dir / "SFX").exists():
            sfx_files = list((audio_dir / "SFX").glob("*.wav"))
        results["sfx"] = (len(sfx_files), 25, [str(f.relative_to(self.project_root)) for f in sfx_files[:5]])
        
        return results
    
    def verify_save_system(self) -> Tuple[bool, Dict[str, bool]]:
        """Verify save system implementation"""
        checks = {
            "save_manager": False,
            "icloud_support": False,
            "auto_save": False,
            "manual_slots": False
        }
        
        save_manager = self.fish_puzzles_dir / "Systems" / "Save" / "SaveManager.swift"
        if save_manager.exists():
            checks["save_manager"] = True
            with open(save_manager, 'r') as f:
                content = f.read()
                if "CloudKit" in content or "iCloud" in content:
                    checks["icloud_support"] = True
                if "autoSave" in content or "autosave" in content.lower():
                    checks["auto_save"] = True
                if "slot" in content.lower():
                    checks["manual_slots"] = True
        
        return all(checks.values()), checks
    
    def verify_build_status(self) -> Tuple[bool, str]:
        """Check if project builds successfully"""
        try:
            # Try to build using xcodebuild
            result = subprocess.run(
                ["make", "build"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                return True, "Build configuration valid"
            else:
                # Check for specific error patterns
                if "CharacterAnimationComponent" in result.stderr:
                    return False, "CharacterAnimationComponent compilation errors"
                else:
                    return False, "Build failed - check Xcode"
        except Exception as e:
            return False, f"Build check failed: {str(e)}"
    
    def verify_compliance(self) -> Dict[str, bool]:
        """Verify compliance requirements"""
        checks = {
            "parental_gate": False,
            "privacy_policy": False,
            "coppa_compliance": False,
            "no_external_tracking": True,  # Assume true unless found
            "kids_category_ready": False
        }
        
        # Check for parental gate implementation
        for swift_file in self.fish_puzzles_dir.glob("**/*.swift"):
            with open(swift_file, 'r') as f:
                content = f.read()
                if "ParentalGate" in content or "parentalGate" in content:
                    checks["parental_gate"] = True
                if "analytics" in content.lower() and "firebase" in content.lower():
                    checks["no_external_tracking"] = False
        
        # Check for privacy policy
        privacy_files = list(self.project_root.glob("**/PRIVACY*")) + list(self.project_root.glob("**/Privacy*"))
        if privacy_files:
            checks["privacy_policy"] = True
        
        # Check Info.plist for kids category settings
        info_plist = self.fish_puzzles_dir / "Info.plist"
        if info_plist.exists():
            with open(info_plist, 'r') as f:
                content = f.read()
                if "ITSAppUsesNonExemptEncryption" in content:
                    checks["kids_category_ready"] = True
        
        return checks
    
    def verify_test_coverage(self) -> Tuple[int, int, List[str]]:
        """Check test implementation"""
        test_files = []
        
        test_dirs = [
            self.project_root / "fish-puzzlesTests",
            self.project_root / "fish-puzzlesUITests"
        ]
        
        for test_dir in test_dirs:
            if test_dir.exists():
                for test_file in test_dir.glob("**/*.swift"):
                    with open(test_file, 'r') as f:
                        content = f.read()
                        if "XCTest" in content and "func test" in content:
                            test_files.append(str(test_file.relative_to(self.project_root)))
        
        # Rough estimate: should have at least 20 test cases for MVP
        return len(test_files), 20, test_files
    
    # ===== PROGRESS CALCULATION =====
    
    def calculate_category_progress(self, category_data: Dict) -> float:
        """Calculate progress for a category based on verification results"""
        total_weight = 0
        weighted_progress = 0
        
        for feature_name, feature_data in category_data["features"].items():
            weight = 1.0  # Equal weight for each feature in category
            
            # Get verification result for this feature
            if feature_name in self.verification_results:
                result = self.verification_results[feature_name]
                if isinstance(result, tuple) and len(result) >= 2:
                    implemented, required = result[0], result[1]
                    progress = min(implemented / required, 1.0) if required > 0 else 0
                elif isinstance(result, bool):
                    progress = 1.0 if result else 0
                else:
                    progress = feature_data.get("implemented", 0)
            else:
                progress = feature_data.get("implemented", 0)
            
            weighted_progress += weight * progress
            total_weight += weight
        
        return (weighted_progress / total_weight * 100) if total_weight > 0 else 0
    
    def run_all_verifications(self):
        """Run all verification checks"""
        print("🔍 Running MVP verification checks...")
        
        # Scene verification
        scenes_impl, scenes_req, scene_files = self.verify_scene_files()
        self.verification_results["locations"] = (scenes_impl, scenes_req, scene_files)
        
        # Puzzle verification
        puzzles_impl, puzzles_req, puzzle_files = self.verify_puzzle_system()
        self.verification_results["puzzles"] = (puzzles_impl, puzzles_req, puzzle_files)
        
        # Character assets
        chars_impl, chars_req, char_files = self.verify_character_assets()
        self.verification_results["characters"] = (chars_impl, chars_req, char_files)
        
        # Background assets
        bgs_impl, bgs_req, bg_files = self.verify_background_assets()
        self.verification_results["backgrounds"] = (bgs_impl, bgs_req, bg_files)
        
        # Audio verification
        audio_results = self.verify_audio_system()
        self.verification_results["audio_system"] = audio_results.get("system", (0, 1, []))
        self.verification_results["music_tracks"] = audio_results.get("music", (0, 2, []))
        self.verification_results["voice_over"] = audio_results.get("voice_over", (0, 100, []))
        self.verification_results["sound_effects"] = audio_results.get("sfx", (0, 25, []))
        
        # Save system
        save_complete, save_checks = self.verify_save_system()
        self.verification_results["save_system"] = (1 if save_complete else 0.7, 1, list(save_checks.keys()))
        
        # Build status
        build_ok, build_msg = self.verify_build_status()
        self.verification_results["build_status"] = (build_ok, build_msg)
        if not build_ok:
            self.blockers.append({"id": "build_failure", "message": build_msg, "severity": "critical"})
        
        # Compliance
        compliance_checks = self.verify_compliance()
        compliance_score = sum(1 for v in compliance_checks.values() if v) / len(compliance_checks)
        self.verification_results["compliance"] = (compliance_score, 1.0, list(compliance_checks.keys()))
        
        # Test coverage
        tests_impl, tests_req, test_files = self.verify_test_coverage()
        self.verification_results["test_coverage"] = (tests_impl, tests_req, test_files)
    
    # ===== REPORT GENERATION =====
    
    def generate_detailed_report(self) -> str:
        """Generate detailed markdown report"""
        report = []
        report.append("# MVP Implementation Report")
        report.append(f"\n**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"**Project Root:** `{self.project_root}`\n")
        
        # Load features config
        config = self.load_features_config()
        
        # Category progress
        report.append("## Category Progress\n")
        overall_progress = 0
        category_weights = []
        
        for category_name, category_data in config.get("categories", {}).items():
            progress = self.calculate_category_progress(category_data)
            weight = category_data.get("weight", 0.1)
            overall_progress += progress * weight
            category_weights.append((category_name.replace("_", " ").title(), progress, weight))
            
            # Progress bar
            filled = int(progress / 5)  # 20 char bar
            bar = "█" * filled + "░" * (20 - filled)
            report.append(f"**{category_name.replace('_', ' ').title()}** [{bar}] {progress:.1f}%")
        
        report.append(f"\n### Overall MVP Progress: {overall_progress:.1f}%\n")
        
        # Critical blockers
        if self.blockers:
            report.append("## 🚨 Critical Blockers\n")
            for blocker in self.blockers:
                report.append(f"- **{blocker['id']}**: {blocker['message']}")
            report.append("")
        
        # Detailed verification results
        report.append("## Verification Details\n")
        
        for key, result in self.verification_results.items():
            if isinstance(result, tuple) and len(result) >= 2:
                if isinstance(result[1], int):  # Has required count
                    impl, req = result[0], result[1]
                    files = result[2] if len(result) > 2 else []
                    
                    status = "✅" if impl >= req else "⚠️" if impl > 0 else "❌"
                    report.append(f"### {key.replace('_', ' ').title()} {status}")
                    report.append(f"- **Status:** {impl}/{req} implemented")
                    
                    if files and len(files) > 0:
                        report.append("- **Files found:**")
                        for f in files[:5]:  # Show first 5
                            report.append(f"  - `{f}`")
                        if len(files) > 5:
                            report.append(f"  - ... and {len(files) - 5} more")
                    report.append("")
        
        # Dependencies and next steps
        report.append("## Next Steps\n")
        
        # Prioritize based on blockers and low completion
        priorities = []
        
        if not self.verification_results.get("build_status", (False,))[0]:
            priorities.append("1. **Fix build errors** - CharacterAnimationComponent compilation")
        
        if self.verification_results.get("puzzles", (0, 1))[0] == 0:
            priorities.append("2. **Implement puzzle system** - No puzzles currently exist")
        
        if self.verification_results.get("backgrounds", (0, 1))[0] == 0:
            priorities.append("3. **Create background art** - No backgrounds created")
        
        for priority in priorities[:5]:
            report.append(priority)
        
        return "\n".join(report)
    
    def generate_dashboard(self) -> str:
        """Generate executive dashboard"""
        config = self.load_features_config()
        
        dashboard = []
        dashboard.append("# MVP Dashboard")
        dashboard.append(f"\n> Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        
        # Calculate overall progress
        overall = 0
        for category_name, category_data in config.get("categories", {}).items():
            progress = self.calculate_category_progress(category_data)
            weight = category_data.get("weight", 0.1)
            overall += progress * weight
        
        dashboard.append(f"> Overall Completion: **{overall:.0f}%**\n")
        
        # Quick status bars
        dashboard.append("## Quick Status\n")
        dashboard.append("```")
        
        for category_name, category_data in config.get("categories", {}).items():
            progress = self.calculate_category_progress(category_data)
            filled = int(progress / 5)
            bar = "█" * filled + "░" * (20 - filled)
            name = category_name.replace("_", " ").title()[:20].ljust(20)
            dashboard.append(f"{name} [{bar}] {progress:3.0f}%")
        
        dashboard.append("```\n")
        
        # Build status
        build_ok = self.verification_results.get("build_status", (False, "Unknown"))[0]
        dashboard.append("## Build Status\n")
        dashboard.append(f"{'✅ **Building Successfully**' if build_ok else '❌ **Build Failing**'}\n")
        
        # Key metrics
        dashboard.append("## Key Metrics\n")
        
        scenes = self.verification_results.get("locations", (0, 0))
        puzzles = self.verification_results.get("puzzles", (0, 0))
        chars = self.verification_results.get("characters", (0, 0))
        
        dashboard.append(f"- **Scenes:** {scenes[0]}/{scenes[1]}")
        dashboard.append(f"- **Puzzles:** {puzzles[0]}/{puzzles[1]}")
        dashboard.append(f"- **Characters:** {chars[0]}/{chars[1]}")
        
        if self.blockers:
            dashboard.append(f"- **Blockers:** {len(self.blockers)} critical issues")
        
        return "\n".join(dashboard)
    
    def update_tracking_files(self):
        """Update all tracking files with latest data"""
        # Generate reports
        detailed_report = self.generate_detailed_report()
        dashboard = self.generate_dashboard()
        
        # Save detailed report
        report_file = self.project_root / "MVP_VERIFICATION_REPORT.md"
        with open(report_file, 'w') as f:
            f.write(detailed_report)
        
        # Update dashboard (preserve manual sections)
        if self.dashboard_file.exists():
            with open(self.dashboard_file, 'r') as f:
                existing = f.read()
            
            # Try to preserve sprint goals and other manual sections
            if "## Sprint Focus Areas" in existing:
                sprint_section = existing.split("## Sprint Focus Areas")[1].split("##")[0]
                dashboard += "\n## Sprint Focus Areas" + sprint_section
        
        with open(self.dashboard_file, 'w') as f:
            f.write(dashboard)
        
        print(f"✅ Updated tracking files:")
        print(f"   - {report_file}")
        print(f"   - {self.dashboard_file}")
    
    def run(self):
        """Main entry point"""
        print("🚀 Fish Puzzles MVP Tracker")
        print("=" * 50)
        
        # Run all verifications
        self.run_all_verifications()
        
        # Update tracking files
        self.update_tracking_files()
        
        # Display summary
        config = self.load_features_config()
        overall = 0
        for category_name, category_data in config.get("categories", {}).items():
            progress = self.calculate_category_progress(category_data)
            weight = category_data.get("weight", 0.1)
            overall += progress * weight
        
        print(f"\n📊 Overall MVP Progress: {overall:.0f}%")
        
        if self.blockers:
            print(f"\n⚠️  {len(self.blockers)} critical blockers found")
            for blocker in self.blockers[:3]:
                print(f"   - {blocker['message']}")

if __name__ == "__main__":
    tracker = MVPTracker()
    tracker.run()