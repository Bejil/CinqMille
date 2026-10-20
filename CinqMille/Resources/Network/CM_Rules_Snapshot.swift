//
//  CM_Rules_Snapshot.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation

/// Règles figées d'une partie réseau (celles de l'hôte au démarrage).
public struct CM_Rules_Snapshot: Codable, Equatable {
	
	public var targetScore:Int
	public var exactScore:Bool
	public var last1000InOneTurn:Bool
	public var openingRequired:Bool
	public var openingScore:Int
	public var equalityKnockback:Bool
	public var diceCount:Int
	public var fiveOnesWin:Bool
	public var fiveFivesWin:Bool
	public var fullEnabled:Bool
	public var threeBallotsPenalty:Bool
	public var multipleOf100Only:Bool
	
	public static func fromCurrentRules() -> CM_Rules_Snapshot {
		
		let rules = CM_Rules.shared
		return CM_Rules_Snapshot(
			targetScore: rules.targetScore,
			exactScore: rules.exactScore,
			last1000InOneTurn: rules.last1000InOneTurn,
			openingRequired: rules.openingRequired,
			openingScore: rules.openingScore,
			equalityKnockback: rules.equalityKnockback,
			diceCount: rules.diceCount,
			fiveOnesWin: rules.fiveOnesWin,
			fiveFivesWin: rules.fiveFivesWin,
			fullEnabled: rules.fullEnabled,
			threeBallotsPenalty: rules.threeBallotsPenalty,
			multipleOf100Only: rules.multipleOf100Only
		)
	}
	
	func firestoreData() -> [String: Any] {
		
		[
			"targetScore": targetScore,
			"exactScore": exactScore,
			"last1000InOneTurn": last1000InOneTurn,
			"openingRequired": openingRequired,
			"openingScore": openingScore,
			"equalityKnockback": equalityKnockback,
			"diceCount": diceCount,
			"fiveOnesWin": fiveOnesWin,
			"fiveFivesWin": fiveFivesWin,
			"fullEnabled": fullEnabled,
			"threeBallotsPenalty": threeBallotsPenalty,
			"multipleOf100Only": multipleOf100Only
		]
	}
	
	static func from(data:[String: Any]?) -> CM_Rules_Snapshot? {
		
		guard let data else { return nil }
		
		return CM_Rules_Snapshot(
			targetScore: CM_Firestore_Parsing.int(data["targetScore"], default: 5000),
			exactScore: CM_Firestore_Parsing.bool(data["exactScore"], default: true),
			last1000InOneTurn: CM_Firestore_Parsing.bool(data["last1000InOneTurn"]),
			openingRequired: CM_Firestore_Parsing.bool(data["openingRequired"], default: true),
			openingScore: CM_Firestore_Parsing.int(data["openingScore"], default: 500),
			equalityKnockback: CM_Firestore_Parsing.bool(data["equalityKnockback"], default: true),
			diceCount: CM_Firestore_Parsing.int(data["diceCount"], default: 5),
			fiveOnesWin: CM_Firestore_Parsing.bool(data["fiveOnesWin"], default: true),
			fiveFivesWin: CM_Firestore_Parsing.bool(data["fiveFivesWin"], default: true),
			fullEnabled: CM_Firestore_Parsing.bool(data["fullEnabled"], default: true),
			threeBallotsPenalty: CM_Firestore_Parsing.bool(data["threeBallotsPenalty"]),
			multipleOf100Only: CM_Firestore_Parsing.bool(data["multipleOf100Only"])
		)
	}
}
