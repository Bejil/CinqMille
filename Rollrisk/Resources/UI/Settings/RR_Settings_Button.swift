//
//  RR_Settings_Button.swift
//  LettroLine
//
//  Created by BLIN Michael on 22/08/2025.
//

import UIKit

public class RR_Settings_Button : RR_Button {
	
	private var settingsMenu:UIMenu {
		
		return .init(children: [
			
			UIAction(title: String(key: "settings.button.sounds"), subtitle: String(key: "settings.button.sounds." + (RR_Audio.shared.isSoundsEnabled ? "on" : "off")), image: UIImage(systemName: RR_Audio.shared.isSoundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"), handler: { [weak self] _ in
				
				UserDefaults.set(!RR_Audio.shared.isSoundsEnabled, .soundsEnabled)
				
				RR_Audio.shared.playSound(.Button)
				
				self?.menu = self?.settingsMenu
			}),
			UIAction(title: String(key: "settings.button.music"), subtitle: String(key: "settings.button.music." + (RR_Audio.shared.isMusicEnabled ? "on" : "off")), image: UIImage(systemName: RR_Audio.shared.isMusicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"), handler: { [weak self] _ in
				
				UserDefaults.set(!RR_Audio.shared.isMusicEnabled, .musicEnabled)
				
				RR_Audio.shared.playSound(.Button)
				
				RR_Audio.shared.isMusicEnabled ? RR_Audio.shared.playMusic() : RR_Audio.shared.stopMusic()
				
				self?.menu = self?.settingsMenu
			}),
			UIAction(title: String(key: "settings.button.vibrations"), subtitle: String(key: "settings.button.vibrations." + (RR_Feedback.shared.isVibrationsEnabled ? "on" : "off")), image: UIImage(systemName: RR_Feedback.shared.isVibrationsEnabled ? "water.waves" : "water.waves.slash"), handler: { [weak self] _ in
				
				UserDefaults.set(!RR_Feedback.shared.isVibrationsEnabled, .vibrationsEnabled)
				
				self?.menu = self?.settingsMenu
			})
		])
	}
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		title = String(key: "settings.button")
		image = UIImage(systemName: "slider.vertical.3")?.applyingSymbolConfiguration(.init(scale: .medium))
		menu = settingsMenu
		showsMenuAsPrimaryAction = true
		type = .navigation
	}
	
	required init?(coder: NSCoder) {
		
		fatalError("init(coder:) has not been implemented")
	}
}
