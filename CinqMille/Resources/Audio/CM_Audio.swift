//
//  CM_Audio.swift
//  CinqMille
//
//  Created by BLIN Michael on 09/10/2025.
//

@preconcurrency import AVFoundation

nonisolated
public final class CM_Audio: NSObject, @unchecked Sendable {
	
	public enum Sounds: String, CaseIterable, Sendable {
		
		case Success = "Success"
		case Error = "Error"
		case Button = "Button"
		case Tap = "Tap"
		case Dice1 = "Dice_1"
		case Dice2 = "Dice_2"
		case Dice3 = "Dice_3"
		case Dice4 = "Dice_4"
		case Dice5 = "Dice_5"
		case Dice6 = "Dice_6"
	}
	
	public static let shared:CM_Audio = .init()
	
	/// Cache des sons pré-chargés pour éviter les délais
	private var soundCache:[Sounds: AVAudioPlayer] = [:]
	
	/// Players de sons actifs (pour permettre plusieurs sons simultanés)
	private var activeSoundPlayers:[AVAudioPlayer] = []
	
	private var musicPlayer:AVAudioPlayer?
	
	/// Queue dédiée pour les opérations audio (évite les freezes sur le main thread)
	private let audioQueue = DispatchQueue(label: "com.cinqmille.audio", qos: .userInteractive)
	
	/// Proxy hors MainActor pour satisfaire AVAudioPlayerDelegate en Swift 6
	private let playerDelegate = PlayerDelegateProxy()
	
	public var isSoundsEnabled:Bool {
		
		(UserDefaults.get(.soundsEnabled) as? Bool) ?? true
	}
	
	public var isMusicEnabled:Bool {
		
		(UserDefaults.get(.musicEnabled) as? Bool) ?? true
	}
	
	public override init() {
		
		super.init()
		
		playerDelegate.owner = self
		
		configureAudioSession()
		preloadSounds()
	}
	
	private func configureAudioSession() {
		
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
			try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
		}
		catch {
			print("Erreur configuration AVAudioSession: \(error)")
		}
	}
	
	private func preloadSounds() {
		
		audioQueue.async { [weak self] in
			
			guard let self else { return }
			
			for sound in Sounds.allCases {
				
				guard let path = Bundle.main.path(forResource: sound.rawValue, ofType: "mp3") else { continue }
				
				let url = URL(fileURLWithPath: path)
				
				if let player = try? AVAudioPlayer(contentsOf: url) {
					
					player.prepareToPlay()
					self.soundCache[sound] = player
				}
			}
		}
	}
	
	public func playSound(_ sound:Sounds) {
		
		guard isSoundsEnabled else { return }
		
		audioQueue.async { [weak self] in
			
			guard let self else { return }
			
			guard let cachedPlayer = self.soundCache[sound],
				  let url = cachedPlayer.url,
				  let player = try? AVAudioPlayer(contentsOf: url) else { return }
			
			player.delegate = self.playerDelegate
			player.prepareToPlay()
			
			self.activeSoundPlayers.append(player)
			player.play()
		}
	}
	
	public func playMusic() {
		
		stopMusic()
		
		guard isMusicEnabled else { return }
		
		guard let index = (0...2).randomElement(),
			  let path = Bundle.main.path(forResource: "music_\(index)", ofType: "mp3") else { return }
		
		let url = URL(fileURLWithPath: path)
		
		guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
		
		musicPlayer = player
		musicPlayer?.delegate = playerDelegate
		musicPlayer?.prepareToPlay()
		musicPlayer?.play()
	}
	
	public func stopMusic() {
		
		musicPlayer?.stop()
		musicPlayer = nil
	}
	
	fileprivate func handlePlayerDidFinish(_ player: AVAudioPlayer) {
		
		if player === musicPlayer {
			playMusic()
		}
		else {
			activeSoundPlayers.removeAll { $0 === player }
		}
	}
}

/// Delegate isolé du MainActor pour pouvoir être assigné depuis `audioQueue`.
nonisolated
private final class PlayerDelegateProxy: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
	
	weak var owner:CM_Audio?
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		
		owner?.handlePlayerDidFinish(player)
	}
}
