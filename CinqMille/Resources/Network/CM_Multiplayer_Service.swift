//
//  CM_Multiplayer_Service.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

public enum CM_Multiplayer_Error: LocalizedError {
	
	case firebaseNotConfigured
	case notAuthenticated
	case roomNotFound
	case roomFull
	case roomAlreadyStarted
	case invalidCode
	case unknown(String)
	
	public var errorDescription:String? {
		
		switch self {
		case .firebaseNotConfigured:
			return String(key: "network.error.firebaseNotConfigured")
		case .notAuthenticated:
			return String(key: "network.error.notAuthenticated")
		case .roomNotFound:
			return String(key: "network.error.roomNotFound")
		case .roomFull:
			return String(key: "network.error.roomFull")
		case .roomAlreadyStarted:
			return String(key: "network.error.roomAlreadyStarted")
		case .invalidCode:
			return String(key: "network.error.invalidCode")
		case .unknown(let message):
			return message
		}
	}
}

public final class CM_Multiplayer_Service {
	
	public static let shared:CM_Multiplayer_Service = .init()
	
	private let roomsCollection = "rooms"
	private var roomListener:ListenerRegistration?
	private var listeningRoomId:String?
	
	public var currentUserId:String? {
		Auth.auth().currentUser?.uid
	}
	
	private var db:Firestore {
		Firestore.firestore()
	}
	
	private init() {}
	
	// MARK: - Auth
	
	@discardableResult
	public func ensureSignedIn() async throws -> String {
		
		guard CM_Firebase.isConfigured || CM_Firebase.configure() else {
			throw CM_Multiplayer_Error.firebaseNotConfigured
		}
		
		if let uid = Auth.auth().currentUser?.uid {
			return uid
		}
		
		let result = try await Auth.auth().signInAnonymously()
		return result.user.uid
	}
	
	// MARK: - Rooms
	
	public func createRoom(playerName:String, maxPlayers:Int = 4) async throws -> CM_Room {
		
		let userId = try await ensureSignedIn()
		let code = try await generateUniqueCode()
		let now = Date()
		
		let host = CM_Room_Player(
			id: userId,
			name: playerName,
			isHost: true,
			isReady: true,
			joinedAt: now
		)
		
		let document = db.collection(roomsCollection).document()
		let room = CM_Room(
			id: document.documentID,
			code: code,
			hostId: userId,
			status: .waiting,
			maxPlayers: max(2, min(maxPlayers, 4)),
			players: [host],
			createdAt: now,
			updatedAt: now,
			rules: CM_Rules_Snapshot.fromCurrentRules()
		)
		
		try await document.setData(room.firestoreData())
		return room
	}
	
	public func joinRoom(code:String, playerName:String) async throws -> CM_Room {
		
		let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		guard normalizedCode.count == 6 else {
			throw CM_Multiplayer_Error.invalidCode
		}
		
		let userId = try await ensureSignedIn()
		
		let snapshot = try await db.collection(roomsCollection)
			.whereField("code", isEqualTo: normalizedCode)
			.limit(to: 1)
			.getDocuments()
		
		guard let document = snapshot.documents.first,
			  var room = CM_Room.from(document: document) else {
			throw CM_Multiplayer_Error.roomNotFound
		}
		
		guard room.status == .waiting else {
			throw CM_Multiplayer_Error.roomAlreadyStarted
		}
		
		if room.player(withId: userId) != nil {
			return room
		}
		
		guard !room.isFull else {
			throw CM_Multiplayer_Error.roomFull
		}
		
		room.players.append(
			CM_Room_Player(
				id: userId,
				name: playerName,
				isHost: false,
				isReady: true,
				joinedAt: .init()
			)
		)
		room.updatedAt = .init()
		
		try await document.reference.setData(room.firestoreData(), merge: true)
		return room
	}
	
	public func leaveRoom(roomId:String) async throws {
		
		guard let userId = currentUserId else { return }
		
		guard var room = try? await fetchRoom(roomId: roomId) else { return }
		
		let wasHost = room.hostId == userId
		room.players.removeAll { $0.id == userId }
		room.updatedAt = .init()
		
		let reference = db.collection(roomsCollection).document(roomId)
		
		// Lobby pas encore démarré : si l'hôte part (ou plus personne), on annule toute la partie
		if room.status == .waiting && (wasHost || room.players.isEmpty) {
			try await reference.delete()
			return
		}
		
		if room.players.isEmpty {
			try await reference.delete()
			return
		}
		
		if wasHost, let newHostIndex = room.players.indices.first {
			room.hostId = room.players[newHostIndex].id
			room.players[newHostIndex].isHost = true
		}
		
		try await reference.setData(room.firestoreData(), merge: true)
	}
	
	public func startGame(roomId:String) async throws {
		
		guard let userId = currentUserId else {
			throw CM_Multiplayer_Error.notAuthenticated
		}
		
		var room = try await fetchRoom(roomId: roomId)
		
		guard room.hostId == userId else {
			throw CM_Multiplayer_Error.unknown(String(key: "network.error.hostOnly"))
		}
		
		guard room.canStart else {
			throw CM_Multiplayer_Error.unknown(String(key: "network.error.notReady"))
		}
		
		let hostRules = CM_Rules_Snapshot.fromCurrentRules()
		room.status = .playing
		room.updatedAt = .init()
		room.rules = hostRules
		room.game = CM_Game_State.initial(
			roomPlayers: room.players,
			diceCount: hostRules.diceCount
		)
		try await db.collection(roomsCollection).document(roomId).setData(room.firestoreData(), merge: true)
	}
	
	public func updateGameState(roomId:String, state:CM_Game_State) async throws {
		
		guard currentUserId != nil else {
			throw CM_Multiplayer_Error.notAuthenticated
		}
		
		let reference = db.collection(roomsCollection).document(roomId)
		
		// Remplace entièrement `game` pour éviter un merge profond qui conserve d'anciens dés
		// Ne pas supprimer ici : les clients doivent pouvoir afficher victoire/défaite avant la purge (lobby / départ).
		try await reference.updateData([
			"game": state.firestoreData(),
			"updatedAt": Timestamp(date: .init()),
			"status": state.status == "finished" ? CM_Room_Status.finished.rawValue : CM_Room_Status.playing.rawValue
		])
	}
	
	/// Parties en statut `waiting` encore joignables.
	public func fetchWaitingRooms() async throws -> [CM_Room] {
		
		_ = try await ensureSignedIn()
		
		let snapshot = try await db.collection(roomsCollection)
			.whereField("status", isEqualTo: CM_Room_Status.waiting.rawValue)
			.getDocuments()
		
		return snapshot.documents
			.compactMap { CM_Room.from(document: $0) }
			.filter { !$0.isFull }
			.sorted { $0.updatedAt > $1.updatedAt }
	}
	
	/// Supprime les documents `finished` (et les lobbys vides) restés en base.
	@discardableResult
	public func cleanupFinishedRooms() async throws -> Int {
		
		_ = try await ensureSignedIn()
		
		let finished = try await db.collection(roomsCollection)
			.whereField("status", isEqualTo: CM_Room_Status.finished.rawValue)
			.getDocuments()
		
		var deleted = 0
		
		for document in finished.documents {
			try await document.reference.delete()
			deleted += 1
		}
		
		return deleted
	}
	
	public func deleteRoom(roomId:String) async throws {
		
		try await db.collection(roomsCollection).document(roomId).delete()
	}
	
	/// Quitte une partie en cours : retire le joueur, passe le tour si besoin, victoire s'il ne reste qu'un joueur.
	@discardableResult
	public func leaveNetworkGame(roomId:String, playerName:String) async throws -> CM_Game_State? {
		
		guard let userId = currentUserId else { return nil }
		
		var room = try await fetchRoom(roomId: roomId)
		let leftName = room.players.first(where: { $0.id == userId })?.name ?? playerName
		let leavingIndex = room.game?.players.firstIndex(where: { $0.id == userId })
		
		room.players.removeAll { $0.id == userId }
		room.updatedAt = .init()
		
		if room.hostId == userId, let newHost = room.players.first {
			room.hostId = newHost.id
			if let index = room.players.firstIndex(where: { $0.id == newHost.id }) {
				room.players[index].isHost = true
			}
		}
		
		var game = room.game
		if var state = game {
			
			let wasCurrent = state.currentPlayerIndex < state.players.count && state.players[state.currentPlayerIndex].id == userId
			state.players.removeAll { $0.id == userId }
			
			if state.players.count <= 1 {
				state.winnerId = state.players.first?.id
				state.status = "finished"
				state.currentPlayerIndex = 0
				state.hasRolledThisTurn = false
				state.currentRollNumber = 0
				state.accumulatedScore = 0
				state.turnScore = 0
				state.scoringDiceIndices = []
			} else if wasCurrent {
				state.currentPlayerIndex %= state.players.count
				state.hasRolledThisTurn = false
				state.currentRollNumber = 0
				state.accumulatedScore = 0
				state.turnScore = 0
				state.scoringDiceIndices = []
				state.dice = state.dice.map { CM_Game_Die_State(value: $0.value, isLocked: false, lockedAtRoll: nil) }
			} else if let leavingIndex {
				if state.currentPlayerIndex > leavingIndex {
					state.currentPlayerIndex -= 1
				}
			}
			
			if state.currentPlayerIndex >= state.players.count {
				state.currentPlayerIndex = 0
			}
			
			state.revision += 1
			state.eventId += 1
			state.eventType = "playerLeft"
			state.eventMessage = leftName
			game = state
			room.game = state
			
			if state.status == "finished" {
				room.status = .finished
			}
		}
		
		let reference = db.collection(roomsCollection).document(roomId)
		
		if room.players.isEmpty {
			try await reference.delete()
			return game
		}
		
		try await reference.setData(room.firestoreData(), merge: true)
		
		// Partie terminée : on laisse le temps aux clients de recevoir l'état, puis on purge
		if room.status == .finished {
			Task {
				try? await Task.sleep(nanoseconds: 2_000_000_000)
				try? await reference.delete()
			}
		}
		
		return game
	}
	
	public func fetchRoom(roomId:String) async throws -> CM_Room {
		
		let document = try await db.collection(roomsCollection).document(roomId).getDocument()
		
		guard let room = CM_Room.from(document: document) else {
			throw CM_Multiplayer_Error.roomNotFound
		}
		
		return room
	}
	
	// MARK: - Listeners
	
	public func listenToRoom(roomId:String, onChange:@escaping (Result<CM_Room, Error>) -> Void) {
		
		stopListening()
		listeningRoomId = roomId
		
		roomListener = db.collection(roomsCollection).document(roomId).addSnapshotListener { [weak self] snapshot, error in
			
			// Ignore les callbacks d'un ancien listener déjà remplacé
			guard self?.listeningRoomId == roomId else { return }
			
			if let error {
				onChange(.failure(error))
				return
			}
			
			guard let snapshot, snapshot.exists, let room = CM_Room.from(document: snapshot) else {
				onChange(.failure(CM_Multiplayer_Error.roomNotFound))
				return
			}
			
			onChange(.success(room))
		}
	}
	
	/// Arrête le listener. Si `roomId` est fourni, n'arrête que s'il correspond encore (évite qu'un écran lobby en deinit coupe la partie).
	public func stopListening(roomId:String? = nil) {
		
		if let roomId, listeningRoomId != roomId {
			return
		}
		
		roomListener?.remove()
		roomListener = nil
		listeningRoomId = nil
	}
	
	// MARK: - Helpers
	
	private func generateUniqueCode() async throws -> String {
		
		for _ in 0..<8 {
			
			let code = CM_Room.generateCode()
			let snapshot = try await db.collection(roomsCollection)
				.whereField("code", isEqualTo: code)
				.limit(to: 1)
				.getDocuments()
			
			if snapshot.documents.isEmpty {
				return code
			}
		}
		
		throw CM_Multiplayer_Error.unknown(String(key: "network.error.codeGeneration"))
	}
}
