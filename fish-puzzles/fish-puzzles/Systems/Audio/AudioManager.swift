//
//  AudioManager.swift
//  fish-puzzles
//
//  Manages all audio playback
//

import AVFoundation
import SpriteKit

final class AudioManager {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var voicePlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playMusic(_ filename: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a") else { 
            print("⚠️ Music file not found: \(filename).m4a - Please add audio files to Resources/Audio/")
            return 
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = volume * GameEngine.shared.gameState.musicVolume
            musicPlayer?.play()
        } catch {
            print("Failed to play music: \(error)")
        }
    }
    
    func playSFX(_ filename: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else { 
            print("⚠️ SFX file not found: \(filename).wav - Please add audio files to Resources/Audio/")
            return 
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume * GameEngine.shared.gameState.sfxVolume
            player.play()
            sfxPlayers.append(player)
            
            // Clean up finished players
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Failed to play SFX: \(error)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}
