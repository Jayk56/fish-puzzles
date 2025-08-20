#!/usr/bin/env python3
"""
MVP Feature Tracking System
Automated verification and progress tracking for Fish Puzzles MVP
"""

import json
import os
import subprocess
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

class MVPTracker:
    def __init__(self, project_root="/Users/jayk/Code/fish-puzzles"):
        self.project_root = Path(project_root)
        self.features_file = self.project_root / "mvp_features.json"
        self.swift_project = self.project_root / "fish-puzzles"
        
    def load_features(self) -> Dict:
        """Load feature definitions from JSON"""
        with open(self.features_file, 'r') as f:
            return json.load(f)
    
    def save_features(self, data: Dict):
        """Save updated feature data"""
        data['last_updated'] = datetime.now().strftime("%Y-%m-%d")
        with open(self.features_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def verify_files_exist(self, files: List[str]) -> float:
        """Check if specified files/directories exist"""
        if not files:
            return 0.0
        
        existing = 0
        for file_path in files:
            full_path = self.swift_project / file_path
            if full_path.exists():
                existing += 1
        
        return existing / len(files) if files else 0
    
    def count_swift_files(self, directory: str) -> int:
        """Count Swift files in a directory"""
        dir_path = self.swift_project / directory
        if not dir_path.exists():
            return 0
        
        return len(list(dir_path.glob("**/*.swift")))
    
    def check_compilation(self) -> bool:
        """Check if project compiles"""
        try:
            result = subprocess.run(
                ["make", "build"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )
            return result.returncode == 0
        except:
            return False
    
    def count_assets(self, asset_type: str) -> int:
        """Count assets of a specific type"""
        assets_dir = self.project_root / "Assets" / "Art"
        if not assets_dir.exists():
            return 0
        
        if asset_type == "backgrounds":
            return len(list(assets_dir.glob("**/Background*.png")))
        elif asset_type == "characters":
            return len(list(assets_dir.glob("**/Character*.png")))
        
        return 0
    
    def check_puzzle_implementation(self) -> Tuple[int, List[str]]:
        """Check for puzzle implementations"""
        puzzle_files = []
        puzzle_pattern = re.compile(r'class\s+\w*Puzzle\w*\s*:\s*\w+')
        
        for swift_file in self.swift_project.glob("**/*.swift"):
            try:
                with open(swift_file, 'r') as f:
                    content = f.read()
                    if puzzle_pattern.search(content):
                        puzzle_files.append(str(swift_file.relative_to(self.swift_project)))
            except:
                continue
        
        return len(puzzle_files), puzzle_files
    
    def calculate_completion(self, features: Dict) -> Dict:
        """Calculate actual completion percentages"""
        results = {}
        
        for category, cat_data in features['categories'].items():
            category_total = 0
            category_implemented = 0
            feature_results = {}
            
            for feature, feat_data in cat_data['features'].items():
                # Auto-verify based on verification type
                if feat_data['verification'] == 'count_scene_files':
                    actual = self.count_swift_files("Scenes")
                    impl = min(1.0, actual / feat_data['required']) if feat_data['required'] else 0
                elif feat_data['verification'] == 'check_puzzle_classes':
                    puzzle_count, _ = self.check_puzzle_implementation()
                    impl = min(1.0, puzzle_count / feat_data['required']) if feat_data['required'] else 0
                elif feat_data['verification'] == 'count_background_assets':
                    actual = self.count_assets("backgrounds")
                    impl = min(1.0, actual / feat_data['required']) if feat_data['required'] else 0
                elif feat_data['verification'] == 'count_character_assets':
                    actual = self.count_assets("characters")
                    impl = min(1.0, actual / feat_data['required']) if feat_data['required'] else 0
                elif feat_data['verification'] == 'compile_check':
                    impl = 1.0 if self.check_compilation() else 0.3
                else:
                    # Use stored implementation value
                    impl = feat_data.get('implemented', 0)
                
                feature_results[feature] = {
                    'required': feat_data['required'],
                    'implemented': impl,
                    'percentage': impl * 100,
                    'blockers': feat_data.get('blockers', [])
                }
                
                category_total += 1
                category_implemented += impl
            
            results[category] = {
                'features': feature_results,
                'total_percentage': (category_implemented / category_total * 100) if category_total else 0,
                'weight': cat_data['weight']
            }
        
        # Calculate overall completion
        overall = sum(results[cat]['total_percentage'] * results[cat]['weight'] 
                     for cat in results)
        
        return {
            'categories': results,
            'overall_completion': overall
        }
    
    def generate_report(self) -> str:
        """Generate a detailed progress report"""
        features = self.load_features()
        completion = self.calculate_completion(features)
        
        report = []
        report.append("=" * 60)
        report.append("MVP IMPLEMENTATION STATUS REPORT")
        report.append("=" * 60)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Overall Completion: {completion['overall_completion']:.1f}%")
        report.append("")
        
        # Progress bar
        progress = int(completion['overall_completion'] / 5)
        bar = "█" * progress + "░" * (20 - progress)
        report.append(f"Progress: [{bar}] {completion['overall_completion']:.1f}%")
        report.append("")
        
        # Category breakdown
        for category, data in completion['categories'].items():
            emoji = self._get_status_emoji(data['total_percentage'])
            report.append(f"\n{emoji} {category.upper().replace('_', ' ')}: {data['total_percentage']:.1f}%")
            report.append("-" * 40)
            
            for feature, feat_data in data['features'].items():
                status = self._get_status_emoji(feat_data['percentage'])
                blockers = " ⚠️ BLOCKED" if feat_data['blockers'] else ""
                report.append(f"  {status} {feature}: {feat_data['percentage']:.0f}%{blockers}")
                
                if feat_data['blockers']:
                    for blocker in feat_data['blockers']:
                        report.append(f"      → {blocker}")
        
        # Critical blockers
        report.append("\n" + "=" * 60)
        report.append("CRITICAL BLOCKERS")
        report.append("-" * 40)
        
        for blocker in features.get('critical_blockers', []):
            report.append(f"\n🚨 {blocker['id']}")
            report.append(f"   Severity: {blocker['severity'].upper()}")
            report.append(f"   {blocker['description']}")
            report.append(f"   Resolution: {blocker['resolution']}")
        
        return "\n".join(report)
    
    def _get_status_emoji(self, percentage: float) -> str:
        """Get status emoji based on completion percentage"""
        if percentage >= 100:
            return "🟢"
        elif percentage >= 50:
            return "🟡"
        elif percentage >= 10:
            return "🟠"
        else:
            return "🔴"
    
    def update_markdown_tracker(self):
        """Update the markdown tracker with latest data"""
        features = self.load_features()
        completion = self.calculate_completion(features)
        
        # Read existing tracker
        tracker_path = self.project_root / "MVP_IMPLEMENTATION_TRACKER.md"
        
        # Update completion percentage in line 151
        with open(tracker_path, 'r') as f:
            lines = f.readlines()
        
        # Update overall completion line
        overall_pct = completion['overall_completion']
        emoji = self._get_status_emoji(overall_pct)
        lines[150] = f"## Overall MVP Completion: {emoji} {overall_pct:.0f}%\n"
        
        # Write back
        with open(tracker_path, 'w') as f:
            f.writelines(lines)
        
        print(f"Updated MVP_IMPLEMENTATION_TRACKER.md with {overall_pct:.0f}% completion")

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Track MVP implementation progress")
    parser.add_argument('--report', action='store_true', help='Generate detailed report')
    parser.add_argument('--update', action='store_true', help='Update tracker files')
    parser.add_argument('--json', action='store_true', help='Output JSON format')
    
    args = parser.parse_args()
    
    tracker = MVPTracker()
    
    if args.json:
        features = tracker.load_features()
        completion = tracker.calculate_completion(features)
        print(json.dumps(completion, indent=2))
    elif args.update:
        tracker.update_markdown_tracker()
        print("Tracker files updated successfully")
    else:
        print(tracker.generate_report())

if __name__ == "__main__":
    main()