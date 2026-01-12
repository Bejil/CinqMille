//
//  CM_Rules.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import Foundation

public class CM_Rules {
	
	public static var shared:CM_Rules = .init()
	
	// MARK: - Objective
	
	public var targetScore:Int {
		
		get { (UserDefaults.get(.rulesTargetScore) as? Int) ?? 5000 }
		set { UserDefaults.set(newValue, .rulesTargetScore) }
	}
	
	public var exactScore:Bool {
		
		get { (UserDefaults.get(.rulesExactScore) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesExactScore) }
	}
	
	public var last1000InOneTurn:Bool {
		
		get { (UserDefaults.get(.rulesLast1000InOneTurn) as? Bool) ?? false }
		set { UserDefaults.set(newValue, .rulesLast1000InOneTurn) }
	}
	
	// MARK: - Opening
	
	public var openingRequired:Bool {
		
		get { (UserDefaults.get(.rulesOpeningRequired) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesOpeningRequired) }
	}
	
	public var openingScore:Int {
		
		get { (UserDefaults.get(.rulesOpeningScore) as? Int) ?? 500 }
		set { UserDefaults.set(newValue, .rulesOpeningScore) }
	}
	
	// MARK: - Equality
	
	public var equalityKnockback:Bool {
		
		get { (UserDefaults.get(.rulesEqualityKnockback) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesEqualityKnockback) }
	}
	
	// MARK: - Dice
	
	public var diceCount:Int {
		
		get { (UserDefaults.get(.rulesDiceCount) as? Int) ?? 5 }
		set { UserDefaults.set(newValue, .rulesDiceCount) }
	}
	
	// MARK: - Special Combinations
	
	public var fiveOnesWin:Bool {
		
		get { (UserDefaults.get(.rulesFiveOnesWin) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesFiveOnesWin) }
	}
	
	public var fiveFivesWin:Bool {
		
		get { (UserDefaults.get(.rulesFiveFivesWin) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesFiveFivesWin) }
	}
	
	public var fullEnabled:Bool {
		
		get { (UserDefaults.get(.rulesFullEnabled) as? Bool) ?? true }
		set { UserDefaults.set(newValue, .rulesFullEnabled) }
	}
	
	// MARK: - Penalties
	
	public var threeBallotsPenalty:Bool {
		
		get { (UserDefaults.get(.rulesThreeBallotsPenalty) as? Bool) ?? false }
		set { UserDefaults.set(newValue, .rulesThreeBallotsPenalty) }
	}
	
	public var multipleOf100Only:Bool {
		
		get { (UserDefaults.get(.rulesMultipleOf100Only) as? Bool) ?? false }
		set { UserDefaults.set(newValue, .rulesMultipleOf100Only) }
	}
	
	// MARK: - Reset
	
	public func reset() {
		
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

