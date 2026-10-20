//
//  CM_Game_State.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation
import FirebaseFirestore

public struct CM_Game_Die_State: Codable, Equatable {
	
	public var value:Int
	public var isLocked:Bool
	public var lockedAtRoll:Int?
	
	public init(value:Int, isLocked:Bool = false, lockedAtRoll:Int? = nil) {
		
		self.value = value
		self.isLocked = isLocked
		self.lockedAtRoll = lockedAtRoll
	}
}

public struct CM_Game_Player_State: Codable, Equatable {
	
	public var id:String
	public var name:String
	public var scores:[Int]
	public var hasOpened:Bool
	
	public init(id:String, name:String, scores:[Int] = [], hasOpened:Bool = false) {
		
		self.id = id
		self.name = name
		self.scores = scores
		self.hasOpened = hasOpened
	}
}

public struct CM_Game_State: Codable, Equatable {
	
	/// Durée maximale d'un tour en multijoueur en ligne (secondes) — réinitialisée à chaque relance (pas au 1er lancer)
	public static let networkTurnDuration: TimeInterval = 25
	
	public var revision:Int
	public var currentPlayerIndex:Int
	public var players:[CM_Game_Player_State]
	public var turnScore:Int
	public var accumulatedScore:Int
	public var hasRolledThisTurn:Bool
	public var currentRollNumber:Int
	public var scoringDiceIndices:[Int]
	public var dice:[CM_Game_Die_State]
	public var isLastRound:Bool
	public var lastRoundTriggerPlayerIndex:Int?
	public var playersWhoPlayedLastRound:[Int]
	public var winnerId:String?
	public var status:String
	/// ballot | combination | playerLeft | timeout
	public var eventType:String?
	public var eventMessage:String?
	public var eventId:Int
	/// Timestamp Unix de fin de tour (décompte synchronisé)
	public var turnEndsAt:Double?
	
	public static func initial(roomPlayers:[CM_Room_Player], diceCount:Int) -> CM_Game_State {
		
		CM_Game_State(
			revision: 1,
			currentPlayerIndex: 0,
			players: roomPlayers.map {
				CM_Game_Player_State(id: $0.id, name: $0.name, scores: [], hasOpened: false)
			},
			turnScore: 0,
			accumulatedScore: 0,
			hasRolledThisTurn: false,
			currentRollNumber: 0,
			scoringDiceIndices: [],
			dice: (0..<diceCount).map { _ in CM_Game_Die_State(value: 1) },
			isLastRound: false,
			lastRoundTriggerPlayerIndex: nil,
			playersWhoPlayedLastRound: [],
			winnerId: nil,
			status: "playing",
			eventType: nil,
			eventMessage: nil,
			eventId: 0,
			turnEndsAt: Date().timeIntervalSince1970 + networkTurnDuration
		)
	}
	
	func firestoreData() -> [String: Any] {
		
		var data:[String: Any] = [
			"revision": revision,
			"currentPlayerIndex": currentPlayerIndex,
			"players": players.map { player in
				[
					"id": player.id,
					"name": player.name,
					"scores": player.scores,
					"hasOpened": player.hasOpened
				] as [String: Any]
			},
			"turnScore": turnScore,
			"accumulatedScore": accumulatedScore,
			"hasRolledThisTurn": hasRolledThisTurn,
			"currentRollNumber": currentRollNumber,
			"scoringDiceIndices": scoringDiceIndices,
			"dice": dice.map { die in
				[
					"value": die.value,
					"isLocked": die.isLocked,
					// Toujours écrire la clé pour écraser une ancienne valeur (merge Firestore)
					"lockedAtRoll": die.lockedAtRoll as Any? ?? NSNull()
				] as [String: Any]
			},
			"isLastRound": isLastRound,
			"playersWhoPlayedLastRound": playersWhoPlayedLastRound,
			"status": status,
			"eventId": eventId,
			"eventType": eventType as Any? ?? NSNull(),
			"eventMessage": eventMessage as Any? ?? NSNull(),
			"winnerId": winnerId as Any? ?? NSNull(),
			"lastRoundTriggerPlayerIndex": lastRoundTriggerPlayerIndex as Any? ?? NSNull(),
			"turnEndsAt": turnEndsAt as Any? ?? NSNull()
		]
		
		return data
	}
	
	static func from(data:[String: Any]?) -> CM_Game_State? {
		
		guard let data else { return nil }
		
		let playersData = data["players"] as? [[String: Any]] ?? []
		let players:[CM_Game_Player_State] = playersData.compactMap { entry in
			
			guard let id = entry["id"] as? String,
				  let name = entry["name"] as? String else { return nil }
			
			return CM_Game_Player_State(
				id: id,
				name: name,
				scores: CM_Firestore_Parsing.intArray(entry["scores"]),
				hasOpened: CM_Firestore_Parsing.bool(entry["hasOpened"])
			)
		}
		
		guard !players.isEmpty else { return nil }
		
		let diceData = data["dice"] as? [[String: Any]] ?? []
		let dice:[CM_Game_Die_State] = diceData.map { entry in
			CM_Game_Die_State(
				value: CM_Firestore_Parsing.int(entry["value"], default: 1),
				isLocked: CM_Firestore_Parsing.bool(entry["isLocked"]),
				lockedAtRoll: CM_Firestore_Parsing.int(entry["lockedAtRoll"])
			)
		}
		
		return CM_Game_State(
			revision: CM_Firestore_Parsing.int(data["revision"], default: 0),
			currentPlayerIndex: CM_Firestore_Parsing.int(data["currentPlayerIndex"], default: 0),
			players: players,
			turnScore: CM_Firestore_Parsing.int(data["turnScore"], default: 0),
			accumulatedScore: CM_Firestore_Parsing.int(data["accumulatedScore"], default: 0),
			hasRolledThisTurn: CM_Firestore_Parsing.bool(data["hasRolledThisTurn"]),
			currentRollNumber: CM_Firestore_Parsing.int(data["currentRollNumber"], default: 0),
			scoringDiceIndices: CM_Firestore_Parsing.intArray(data["scoringDiceIndices"]),
			dice: dice,
			isLastRound: CM_Firestore_Parsing.bool(data["isLastRound"]),
			lastRoundTriggerPlayerIndex: CM_Firestore_Parsing.int(data["lastRoundTriggerPlayerIndex"]),
			playersWhoPlayedLastRound: CM_Firestore_Parsing.intArray(data["playersWhoPlayedLastRound"]),
			winnerId: data["winnerId"] as? String,
			status: data["status"] as? String ?? "playing",
			eventType: data["eventType"] as? String,
			eventMessage: data["eventMessage"] as? String,
			eventId: CM_Firestore_Parsing.int(data["eventId"], default: 0),
			turnEndsAt: CM_Firestore_Parsing.double(data["turnEndsAt"])
		)
	}
}
