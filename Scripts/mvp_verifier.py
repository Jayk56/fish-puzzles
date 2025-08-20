#!/usr/bin/env python3
"""
MVP Feature Verifier - Deep code analysis and dependency tracking
Provides detailed verification of implementation quality and completeness.
"""

import os
import re
import ast
import json
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional
from dataclasses import dataclass, field
from collections import defaultdict
import subprocess

@dataclass
class FeatureStatus:
    """Status of a single feature"""
    name: str
    implemented: float  # 0.0 to 1.0
    quality: float  # 0.0 to 1.0 (code quality score)
    files: List[str] = field(default_factory=list)
    missing_components: List[str] = field(default_factory=list)
    dependencies: Set[str] = field(default_factory=set)
    blockers: List[str] = field(default_factory=list)
    tests: List[str] = field(default_factory=list)
    
    @property
    def overall_score(self) -> float:
        return (self.implemented * 0.7 + self.quality * 0.3)

class CodeAnalyzer:
    """Analyzes Swift code for quality and completeness"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.fish_puzzles_dir = project_root / "fish-puzzles"
        
    def analyze_swift_file(self, file_path: Path) -> Dict:
        """Analyze a Swift file for various metrics"""
        metrics = {
            "classes": [],
            "protocols": [],
            "functions": [],
            "imports": [],
            "todos": [],
            "fixmes": [],
            "has_tests": False,
            "has_documentation": False,
            "line_count": 0,
            "complexity": 0
        }
        
        if not file_path.exists():
            return metrics
            
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.split('\n')
            metrics["line_count"] = len(lines)
            
            # Extract classes
            class_pattern = r'class\s+(\w+)'
            metrics["classes"] = re.findall(class_pattern, content)
            
            # Extract protocols
            protocol_pattern = r'protocol\s+(\w+)'
            metrics["protocols"] = re.findall(protocol_pattern, content)
            
            # Extract functions
            func_pattern = r'func\s+(\w+)'
            metrics["functions"] = re.findall(func_pattern, content)
            
            # Extract imports
            import_pattern = r'import\s+(\w+)'
            metrics["imports"] = re.findall(import_pattern, content)
            
            # Find TODOs and FIXMEs
            for line in lines:
                if "TODO:" in line:
                    metrics["todos"].append(line.strip())
                if "FIXME:" in line:
                    metrics["fixmes"].append(line.strip())
            
            # Check for tests
            if "XCTest" in content or "func test" in content:
                metrics["has_tests"] = True
            
            # Check for documentation
            if "///" in content or "/**" in content:
                metrics["has_documentation"] = True
            
            # Rough complexity estimate (number of control flow statements)
            control_flow = ['if ', 'else ', 'for ', 'while ', 'switch ', 'guard ']
            metrics["complexity"] = sum(content.count(cf) for cf in control_flow)
            
        return metrics

class FeatureVerifier:
    """Verifies specific feature implementations"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.fish_puzzles_dir = project_root / "fish-puzzles"
        self.analyzer = CodeAnalyzer(project_root)
        self.feature_status = {}
        
    def verify_ecs_architecture(self) -> FeatureStatus:
        """Verify Entity-Component System implementation"""
        status = FeatureStatus(name="ECS Architecture", implemented=0.0, quality=0.0)
        
        ecs_dir = self.fish_puzzles_dir / "Core" / "ECS"
        
        # Required ECS components
        required_files = {
            "Entity.swift": "Base entity class",
            "Component.swift": "Component protocol/base",
            "System.swift": "System base class"
        }
        
        for file_name, description in required_files.items():
            file_path = ecs_dir / file_name
            if file_path.exists():
                status.files.append(str(file_path.relative_to(self.project_root)))
                
                # Analyze the file
                metrics = self.analyzer.analyze_swift_file(file_path)
                if metrics["has_documentation"]:
                    status.quality += 0.1
                if metrics["has_tests"]:
                    status.quality += 0.1
            else:
                status.missing_components.append(f"{description} ({file_name})")
        
        # Check for CharacterAnimationComponent
        anim_component = self.fish_puzzles_dir / "Components" / "CharacterAnimationComponent.swift"
        if anim_component.exists():
            # Check if it compiles
            result = subprocess.run(
                ["swiftc", "-parse", str(anim_component)],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                status.blockers.append("CharacterAnimationComponent has compilation errors")
                status.implemented = 0.5  # Partial implementation
            else:
                status.implemented = 0.8
        
        # Calculate overall implementation
        if status.files:
            status.implemented = max(status.implemented, len(status.files) / len(required_files))
        
        status.quality = min(status.quality, 1.0)
        
        return status
    
    def verify_interaction_system(self) -> FeatureStatus:
        """Verify touch and interaction handling"""
        status = FeatureStatus(name="Interaction System", implemented=0.0, quality=0.0)
        
        interaction_dir = self.fish_puzzles_dir / "Systems" / "Interaction"
        
        required_components = [
            "InteractionSystem.swift",
            "TouchHandler.swift",
            "DragDropSystem.swift",
            "TapHandler.swift"
        ]
        
        for component in required_components:
            file_path = interaction_dir / component
            if file_path.exists():
                status.files.append(str(file_path.relative_to(self.project_root)))
                metrics = self.analyzer.analyze_swift_file(file_path)
                
                # Check for proper implementation
                if "handleTouch" in str(metrics["functions"]):
                    status.implemented += 0.25
                if metrics["has_documentation"]:
                    status.quality += 0.25
        
        # Check integration with scenes
        base_scene = self.fish_puzzles_dir / "Scenes" / "Base" / "BaseGameScene.swift"
        if base_scene.exists():
            metrics = self.analyzer.analyze_swift_file(base_scene)
            if "touchesBegan" in str(metrics["functions"]):
                status.implemented = min(status.implemented + 0.2, 1.0)
        
        status.dependencies.add("ECS Architecture")
        
        return status
    
    def verify_save_system(self) -> FeatureStatus:
        """Verify save and persistence system"""
        status = FeatureStatus(name="Save System", implemented=0.0, quality=0.0)
        
        save_manager = self.fish_puzzles_dir / "Systems" / "Save" / "SaveManager.swift"
        
        if save_manager.exists():
            status.files.append(str(save_manager.relative_to(self.project_root)))
            
            with open(save_manager, 'r') as f:
                content = f.read()
                
                # Check for required functionality
                features = {
                    "save": "save" in content.lower(),
                    "load": "load" in content.lower(),
                    "auto_save": "autosave" in content.lower() or "autoSave" in content,
                    "icloud": "CloudKit" in content or "iCloud" in content,
                    "slots": "slot" in content.lower()
                }
                
                implemented_features = sum(1 for v in features.values() if v)
                status.implemented = implemented_features / len(features)
                
                # Check for error handling
                if "try" in content and "catch" in content:
                    status.quality += 0.3
                
                # Check for tests
                test_file = self.project_root / "fish-puzzlesTests" / "SaveManagerTests.swift"
                if test_file.exists():
                    status.tests.append(str(test_file.relative_to(self.project_root)))
                    status.quality += 0.3
        else:
            status.missing_components.append("SaveManager.swift")
            status.blockers.append("Save system not implemented")
        
        return status
    
    def verify_puzzle_framework(self) -> FeatureStatus:
        """Verify puzzle system framework"""
        status = FeatureStatus(name="Puzzle Framework", implemented=0.0, quality=0.0)
        
        puzzle_dir = self.fish_puzzles_dir / "Puzzles"
        
        # Check for base puzzle classes
        required_components = {
            "Puzzle.swift": "Base puzzle class",
            "PuzzleManager.swift": "Puzzle state management",
            "PuzzleSolution.swift": "Solution checking"
        }
        
        for file_name, description in required_components.items():
            file_path = puzzle_dir / file_name
            if file_path.exists():
                status.files.append(str(file_path.relative_to(self.project_root)))
                status.implemented += 0.33
            else:
                status.missing_components.append(description)
        
        # Check for actual puzzle implementations
        if puzzle_dir.exists():
            puzzle_files = list(puzzle_dir.glob("*Puzzle.swift"))
            if puzzle_files:
                status.files.extend([str(f.relative_to(self.project_root)) for f in puzzle_files])
                status.implemented = min(status.implemented + len(puzzle_files) * 0.1, 1.0)
        
        if status.implemented == 0:
            status.blockers.append("No puzzle framework exists")
        
        status.dependencies.add("Interaction System")
        status.dependencies.add("Inventory System")
        
        return status
    
    def verify_ui_system(self) -> FeatureStatus:
        """Verify UI/HUD implementation"""
        status = FeatureStatus(name="UI System", implemented=0.0, quality=0.0)
        
        ui_dir = self.fish_puzzles_dir / "UI"
        hud_dir = ui_dir / "HUD"
        
        required_overlays = [
            "HUDOverlay.swift",
            "InventoryOverlay.swift",
            "DialogueOverlay.swift",
            "SettingsOverlay.swift",
            "MapOverlay.swift"
        ]
        
        for overlay in required_overlays:
            file_path = hud_dir / overlay
            if file_path.exists():
                status.files.append(str(file_path.relative_to(self.project_root)))
                status.implemented += 0.2
                
                metrics = self.analyzer.analyze_swift_file(file_path)
                if metrics["has_documentation"]:
                    status.quality += 0.1
        
        # Check safe area management
        safe_area = ui_dir / "SafeAreaManager.swift"
        if safe_area.exists():
            status.files.append(str(safe_area.relative_to(self.project_root)))
            status.quality += 0.2
        
        status.quality = min(status.quality, 1.0)
        
        return status
    
    def verify_audio_system(self) -> FeatureStatus:
        """Verify audio system implementation"""
        status = FeatureStatus(name="Audio System", implemented=0.0, quality=0.0)
        
        audio_manager = self.fish_puzzles_dir / "Systems" / "Audio" / "AudioManager.swift"
        
        if audio_manager.exists():
            status.files.append(str(audio_manager.relative_to(self.project_root)))
            
            with open(audio_manager, 'r') as f:
                content = f.read()
                
                # Check for required functionality
                features = {
                    "play_music": "playMusic" in content or "playBackgroundMusic" in content,
                    "play_sfx": "playSFX" in content or "playSound" in content,
                    "volume_control": "volume" in content.lower(),
                    "audio_session": "AVAudioSession" in content,
                    "pause_resume": "pause" in content and "resume" in content
                }
                
                implemented = sum(1 for v in features.values() if v)
                status.implemented = implemented / len(features)
                
                # Check imports
                if "import AVFoundation" in content:
                    status.quality += 0.3
        else:
            status.missing_components.append("AudioManager.swift")
            status.blockers.append("Audio system not implemented")
        
        # Check for audio assets
        audio_dir = self.project_root / "Assets" / "Audio"
        if audio_dir.exists():
            music_files = list((audio_dir / "Music").glob("*")) if (audio_dir / "Music").exists() else []
            sfx_files = list((audio_dir / "SFX").glob("*")) if (audio_dir / "SFX").exists() else []
            vo_files = list((audio_dir / "VO").glob("*")) if (audio_dir / "VO").exists() else []
            
            if not music_files:
                status.missing_components.append("Music tracks")
            if not sfx_files:
                status.missing_components.append("Sound effects")
            if not vo_files:
                status.missing_components.append("Voice over files")
        else:
            status.blockers.append("No audio assets directory")
        
        return status
    
    def generate_dependency_graph(self, features: Dict[str, FeatureStatus]) -> str:
        """Generate a dependency graph in Mermaid format"""
        graph = ["```mermaid", "graph TD"]
        
        # Add nodes
        for name, status in features.items():
            node_id = name.replace(" ", "_")
            color = "green" if status.implemented > 0.8 else "yellow" if status.implemented > 0.3 else "red"
            score = int(status.overall_score * 100)
            graph.append(f"    {node_id}[{name}<br/>{score}%]")
            
            # Style based on implementation
            if color == "green":
                graph.append(f"    style {node_id} fill:#9f9")
            elif color == "yellow":
                graph.append(f"    style {node_id} fill:#ff9")
            else:
                graph.append(f"    style {node_id} fill:#f99")
        
        # Add dependencies
        for name, status in features.items():
            node_id = name.replace(" ", "_")
            for dep in status.dependencies:
                dep_id = dep.replace(" ", "_")
                graph.append(f"    {dep_id} --> {node_id}")
        
        graph.append("```")
        return "\n".join(graph)
    
    def verify_all_features(self) -> Dict[str, FeatureStatus]:
        """Run all feature verifications"""
        features = {}
        
        print("🔍 Verifying feature implementations...")
        
        # Core systems
        features["ECS Architecture"] = self.verify_ecs_architecture()
        features["Interaction System"] = self.verify_interaction_system()
        features["Save System"] = self.verify_save_system()
        features["Puzzle Framework"] = self.verify_puzzle_framework()
        features["UI System"] = self.verify_ui_system()
        features["Audio System"] = self.verify_audio_system()
        
        return features
    
    def generate_quality_report(self, features: Dict[str, FeatureStatus]) -> str:
        """Generate a quality and completeness report"""
        report = ["# MVP Quality Report\n"]
        
        # Overall metrics
        total_impl = sum(f.implemented for f in features.values()) / len(features)
        total_quality = sum(f.quality for f in features.values()) / len(features)
        total_score = sum(f.overall_score for f in features.values()) / len(features)
        
        report.append(f"## Overall Metrics")
        report.append(f"- **Implementation:** {total_impl:.0%}")
        report.append(f"- **Quality Score:** {total_quality:.0%}")
        report.append(f"- **Combined Score:** {total_score:.0%}\n")
        
        # Critical blockers
        all_blockers = []
        for feature in features.values():
            for blocker in feature.blockers:
                all_blockers.append(f"- **{feature.name}:** {blocker}")
        
        if all_blockers:
            report.append("## 🚨 Critical Blockers\n")
            report.extend(all_blockers)
            report.append("")
        
        # Feature details
        report.append("## Feature Analysis\n")
        
        for name, status in sorted(features.items(), key=lambda x: x[1].overall_score):
            report.append(f"### {name}")
            report.append(f"- **Implementation:** {status.implemented:.0%}")
            report.append(f"- **Quality:** {status.quality:.0%}")
            report.append(f"- **Overall:** {status.overall_score:.0%}")
            
            if status.missing_components:
                report.append("- **Missing:**")
                for comp in status.missing_components:
                    report.append(f"  - {comp}")
            
            if status.dependencies:
                report.append(f"- **Dependencies:** {', '.join(status.dependencies)}")
            
            if status.tests:
                report.append(f"- **Tests:** {len(status.tests)} test files")
            
            report.append("")
        
        # Dependency graph
        report.append("## Dependency Graph\n")
        report.append(self.generate_dependency_graph(features))
        
        return "\n".join(report)

def main():
    """Main entry point for feature verification"""
    project_root = Path.cwd()
    verifier = FeatureVerifier(project_root)
    
    # Verify all features
    features = verifier.verify_all_features()
    
    # Generate quality report
    report = verifier.generate_quality_report(features)
    
    # Save report
    report_file = project_root / "MVP_QUALITY_REPORT.md"
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"✅ Quality report saved to: {report_file}")
    
    # Print summary
    total_score = sum(f.overall_score for f in features.values()) / len(features)
    print(f"\n📊 Overall Quality Score: {total_score:.0%}")
    
    blockers = sum(len(f.blockers) for f in features.values())
    if blockers > 0:
        print(f"⚠️  {blockers} blockers found across features")

if __name__ == "__main__":
    main()