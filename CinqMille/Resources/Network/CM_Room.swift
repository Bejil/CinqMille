//
//  CM_Room.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation
import FirebaseFirestore

public struct CM_Room_Player: Codable, Equatable, Hashable {
	
	public var id:String
	public var name:String
	public var isHost:Bool
	public var isReady:Bool
	public var joinedAt:Date
	
	public init(id:String, name:String, isHost:Bool, isReady:Bool = false, joinedAt:Date = .init()) {
		
		self.id = id
		self.name = name
		self.isHost = isHost
		self.isReady = isReady
		self.joinedAt = joinedAt
	}
}

public enum CM_Room_Status: String, Codable {
	
	case waiting
	case playing
	case finished
}

public struct CM_Room: Codable, Equatable {
	
	public var id:String
	public var code:String
	public var hostId:String
	public var status:CM_Room_Status
	public var maxPlayers:Int
	public var players:[CM_Room_Player]
	public var createdAt:Date
	public var updatedAt:Date
	public var game:CM_Game_State?
	/// Règles de l'hôte, figées au démarrage de la partie.
	public var rules:CM_Rules_Snapshot?
	
	public var isFull:Bool {
		players.count >= maxPlayers
	}
	
	public var canStart:Bool {
		status == .waiting && players.count >= 2 && players.allSatisfy(\.isReady)
	}
	
	public var allPlayersReady:Bool {
		!players.isEmpty && players.allSatisfy(\.isReady)
	}
	
	public init(id:String,
				code:String,
				hostId:String,
				status:CM_Room_Status = .waiting,
				maxPlayers:Int = 4,
				players:[CM_Room_Player] = [],
				createdAt:Date = .init(),
				updatedAt:Date = .init(),
				game:CM_Game_State? = nil,
				rules:CM_Rules_Snapshot? = nil) {
		
		self.id = id
		self.code = code
		self.hostId = hostId
		self.status = status
		self.maxPlayers = maxPlayers
		self.players = players
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.game = game
		self.rules = rules
	}
	
	public func player(withId playerId:String) -> CM_Room_Player? {
		players.first { $0.id == playerId }
	}
}

extension CM_Room {
	
	static func generateCode(length:Int = 6) -> String {
		
		let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
		return String((0..<length).compactMap { _ in alphabet.randomElement() })
	}
	
	func firestoreData() -> [String: Any] {
		
		var data:[String: Any] = [
			"code": code,
			"hostId": hostId,
			"status": status.rawValue,
			"maxPlayers": maxPlayers,
			"players": players.map { player in
				[
					"id": player.id,
					"name": player.name,
					"isHost": player.isHost,
					"isReady": player.isReady,
					"joinedAt": Timestamp(date: player.joinedAt)
				] as [String: Any]
			},
			"createdAt": Timestamp(date: createdAt),
			"updatedAt": Timestamp(date: updatedAt)
		]
		
		if let game {
			data["game"] = game.firestoreData()
		}
		
		if let rules {
			data["rules"] = rules.firestoreData()
		}
		
		return data
	}
	
	static func from(document: DocumentSnapshot) -> CM_Room? {
		
		guard let data = document.data() else { return nil }
		
		let playersData = data["players"] as? [[String: Any]] ?? []
		let players:[CM_Room_Player] = playersData.compactMap { entry in
			
			guard let id = entry["id"] as? String,
				  let name = entry["name"] as? String else { return nil }
			
			let joinedAt:Date
			if let timestamp = entry["joinedAt"] as? Timestamp {
				joinedAt = timestamp.dateValue()
			} else {
				joinedAt = .init()
			}
			
			return CM_Room_Player(
				id: id,
				name: name,
				isHost: entry["isHost"] as? Bool ?? false,
				isReady: entry["isReady"] as? Bool ?? false,
				joinedAt: joinedAt
			)
		}
		
		let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .init()
		let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
		let status = CM_Room_Status(rawValue: data["status"] as? String ?? "") ?? .waiting
		
		return CM_Room(
			id: document.documentID,
			code: data["code"] as? String ?? "",
			hostId: data["hostId"] as? String ?? "",
			status: status,
			maxPlayers: CM_Firestore_Parsing.int(data["maxPlayers"], default: 4),
			players: players.sorted { $0.joinedAt < $1.joinedAt },
			createdAt: createdAt,
			updatedAt: updatedAt,
			game: CM_Game_State.from(data: data["game"] as? [String: Any]),
			rules: CM_Rules_Snapshot.from(data: data["rules"] as? [String: Any])
		)
	}
}
