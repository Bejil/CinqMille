//
//  RR_Audio.swift
//  LetttroLine
//
//  Created by BLIN Michael on 09/10/2025.
//

import AVFoundation

public class RR_Audio : NSObject {
	
	public enum Sounds : String {
		
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
	
	public static var shared:RR_Audio = .init()
	private var soundPlayer:AVAudioPlayer?
	private var musicPlayer:AVAudioPlayer?
	public var isSoundsEnabled:Bool {
		
		return (UserDefaults.get(.soundsEnabled) as? Bool) ?? true
	}
	public var isMusicEnabled:Bool {
		
		return (UserDefaults.get(.musicEnabled) as? Bool) ?? true
	}
	
	public func playSound(_ sound:Sounds) {
		
		stopSound()
		
		if isSoundsEnabled, let path = Bundle.main.path(forResource: sound.rawValue, ofType: "mp3") {
			
			let url = URL(fileURLWithPath: path)
			
			try?AVAudioSession.sharedInstance().setCategory(.playback)
			try?AVAudioSession.sharedInstance().setActive(true)
			
			try?soundPlayer = AVAudioPlayer(contentsOf: url)
			soundPlayer?.prepareToPlay()
			soundPlayer?.play()
		}
	}
	
	private func stopSound() {
		
		soundPlayer?.stop()
		soundPlayer = nil
	}
	
	public func playMusic() {
		
		stopMusic()
		
		if isMusicEnabled, let index = (0...2).randomElement(), let path = Bundle.main.path(forResource: "music_\(index)", ofType: "mp3") {
			
			let url = URL(fileURLWithPath: path)
			
			try?AVAudioSession.sharedInstance().setCategory(.playback)
			try?AVAudioSession.sharedInstance().setActive(true)
			
			try?musicPlayer = AVAudioPlayer(contentsOf: url)
			musicPlayer?.delegate = self
			musicPlayer?.prepareToPlay()
			musicPlayer?.play()
		}
	}
	
	public func stopMusic() {
		
		musicPlayer?.stop()
		musicPlayer = nil
	}
}

extension RR_Audio : AVAudioPlayerDelegate {
	
	public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		
		playMusic()
	}
}
