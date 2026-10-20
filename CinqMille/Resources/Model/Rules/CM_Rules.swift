//
//  CM_Rules.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import Foundation

public class CM_Rules {
	
	public static var shared:CM_Rules = .init()
	
	/// Règles de l'hôte pendant une partie réseau (ne modifie pas les UserDefaults locaux).
	private var sessionOverride:CM_Rules_Snapshot?
	
	public var hasSessionOverride:Bool {
		sessionOverride != nil
	}
	
	public func applySessionRules(_ snapshot:CM_Rules_Snapshot?) {
		sessionOverride = snapshot
	}
	
	public func clearSessionRules() {
		sessionOverride = nil
	}
	
	// MARK: - Objective
	
	public var targetScore:Int {
		
		get { sessionOverride?.targetScore ?? (UserDefaults.get(.rulesTargetScore) as? Int) ?? 5000 }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesTargetScore)
		}
	}
	
	public var exactScore:Bool {
		
		get { sessionOverride?.exactScore ?? (UserDefaults.get(.rulesExactScore) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesExactScore)
		}
	}
	
	public var last1000InOneTurn:Bool {
		
		get { sessionOverride?.last1000InOneTurn ?? (UserDefaults.get(.rulesLast1000InOneTurn) as? Bool) ?? false }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesLast1000InOneTurn)
		}
	}
	
	// MARK: - Opening
	
	public var openingRequired:Bool {
		
		get { sessionOverride?.openingRequired ?? (UserDefaults.get(.rulesOpeningRequired) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesOpeningRequired)
		}
	}
	
	public var openingScore:Int {
		
		get { sessionOverride?.openingScore ?? (UserDefaults.get(.rulesOpeningScore) as? Int) ?? 500 }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesOpeningScore)
		}
	}
	
	// MARK: - Equality
	
	public var equalityKnockback:Bool {
		
		get { sessionOverride?.equalityKnockback ?? (UserDefaults.get(.rulesEqualityKnockback) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesEqualityKnockback)
		}
	}
	
	// MARK: - Dice
	
	public var diceCount:Int {
		
		get { sessionOverride?.diceCount ?? (UserDefaults.get(.rulesDiceCount) as? Int) ?? 5 }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesDiceCount)
		}
	}
	
	// MARK: - Special Combinations
	
	public var fiveOnesWin:Bool {
		
		get { sessionOverride?.fiveOnesWin ?? (UserDefaults.get(.rulesFiveOnesWin) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesFiveOnesWin)
		}
	}
	
	public var fiveFivesWin:Bool {
		
		get { sessionOverride?.fiveFivesWin ?? (UserDefaults.get(.rulesFiveFivesWin) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesFiveFivesWin)
		}
	}
	
	public var fullEnabled:Bool {
		
		get { sessionOverride?.fullEnabled ?? (UserDefaults.get(.rulesFullEnabled) as? Bool) ?? true }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesFullEnabled)
		}
	}
	
	// MARK: - Penalties
	
	public var threeBallotsPenalty:Bool {
		
		get { sessionOverride?.threeBallotsPenalty ?? (UserDefaults.get(.rulesThreeBallotsPenalty) as? Bool) ?? false }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesThreeBallotsPenalty)
		}
	}
	
	public var multipleOf100Only:Bool {
		
		get { sessionOverride?.multipleOf100Only ?? (UserDefaults.get(.rulesMultipleOf100Only) as? Bool) ?? false }
		set {
			guard sessionOverride == nil else { return }
			UserDefaults.set(newValue, .rulesMultipleOf100Only)
		}
	}
	
	// MARK: - Reset
	
	public func reset() {
		
		guard sessionOverride == nil else { return }
		
		targetScore = 5000
		exactScore = true
		last1000InOneTurn = false
		openingRequired = true
		openingScore = 500
		equalityKnockback = true
		diceCount = 5
		fiveOnesWin = true
		fiveFivesWin = true
		fullEnabled = true
		threeBallotsPenalty = false
		multipleOf100Only = false
	}
}
