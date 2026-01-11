//
//  UserDefaults_Extension.swift
//  ListYa
//
//  Created by BLIN Michael on 21/06/2022.
//

import Foundation

extension UserDefaults {

	public enum Keys : String, CaseIterable {
		
		// Ads
		case shouldDisplayAds = "shouldDisplayAds"
		
		//InAppPurchase
		case inAppPurchaseAlertCapping = "inAppPurchaseAlertCapping"
		
		// Player
		case currentPlayer = "currentPlayer"
		
		// Settings
		case vibrationsEnabled = "vibrationsEnabled"
		case musicEnabled = "musicEnabled"
		case soundsEnabled = "soundsEnabled"
		
		// Rules - Objective
		case rulesTargetScore = "rulesTargetScore"
		case rulesExactScore = "rulesExactScore"
		case rulesLast1000InOneTurn = "rulesLast1000InOneTurn"
		
		// Rules - Opening
		case rulesOpeningRequired = "rulesOpeningRequired"
		case rulesOpeningScore = "rulesOpeningScore"
		
		// Rules - Equality
		case rulesEqualityKnockback = "rulesEqualityKnockback"
		
		// Rules - Dice
		case rulesDiceCount = "rulesDiceCount"
		
		// Rules - Special Combinations
		case rulesFiveOnesWin = "rulesFiveOnesWin"
		case rulesFiveFivesWin = "rulesFiveFivesWin"
		case rulesFullEnabled = "rulesFullEnabled"
		
		// Rules - Penalties
		case rulesThreeBallotsPenalty = "rulesThreeBallotsPenalty"
		case rulesMultipleOf100Only = "rulesMultipleOf100Only"
		
		// Tutorials
		case gameTutorialShown = "gameTutorialShown"
		case diceSelectionTutorialShown = "diceSelectionTutorialShown"
		case selectedDiceTutorialShown = "selectedDiceTutorialShown"
		
		// Theme
		case theme = "theme"
	}
	
	public static func set(_ value:Any?, _ key:UserDefaults.Keys) {
		
		let standardUserDefaults = UserDefaults.standard
		standardUserDefaults.set(value, forKey: key.rawValue)
		standardUserDefaults.synchronize()
	}
	
	public static func get(_ key:UserDefaults.Keys) -> Any? {
		
		let standardUserDefaults = UserDefaults.standard
		return standardUserDefaults.value(forKey: key.rawValue)
	}
	
	public static func delete(_ key:UserDefaults.Keys) {
		
		let standardUserDefaults = UserDefaults.standard
		standardUserDefaults.removeObject(forKey: key.rawValue)
		standardUserDefaults.synchronize()
	}
	
	public static func reset() {
		
		Keys.allCases.forEach({ delete($0) })
	}
	
	public func resetAll() {
		
		let domain = Bundle.main.bundleIdentifier
		let standardUserDefaults = UserDefaults.standard
		standardUserDefaults.removePersistentDomain(forName: domain!)
		standardUserDefaults.synchronize()
	}
}
