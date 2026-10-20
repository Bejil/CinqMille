//
//  CM_Network_Game_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import UIKit

/// Partie multijoueur en ligne synchronisée via Firestore.
public class CM_Network_Game_ViewController: CM_Game_ViewController {
	
	private let initialRoom:CM_Room
	private var matchRules:CM_Rules_Snapshot?
	private var didStart:Bool = false
	private var isLeaving:Bool = false
	
	public init(room:CM_Room) {
		
		self.initialRoom = room
		self.matchRules = room.rules
		super.init(nibName: nil, bundle: nil)
	}
	
	@MainActor required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func loadView() {
		
		super.loadView()
		
		isNetworkMultiplayer = true
		isLocalMultiplayer = true
		isModal = true
		title = String(key: "network.game.title")
		networkRoomId = initialRoom.id
		networkUserId = CM_Multiplayer_Service.shared.currentUserId
		
		let playerName = initialRoom.players.first(where: { $0.id == networkUserId })?.name
			?? CM_Player.current.name
			?? "?"
		CM_Multiplayer_Service.shared.rememberActiveRoom(roomId: initialRoom.id, playerName: playerName)
		
		let rulesButton = CM_Button() { [weak self] _ in
			self?.presentMatchRules()
		}
		rulesButton.image = UIImage(systemName: "list.clipboard.fill")?.applyingSymbolConfiguration(.init(scale: .small))
        rulesButton.title = String(key: "rules.button")
		rulesButton.configuration?.imagePadding = UI.Margins/2
		rulesButton.type = .navigation
		
		var rightItems:[UIBarButtonItem] = [.init(customView: rulesButton)]
		if let existing = navigationItem.rightBarButtonItem {
			(existing.customView as? CM_Settings_Button)?.hidesAutoPass = true
			rightItems.append(existing)
		}
		navigationItem.rightBarButtonItems = rightItems
	}
	
	private func presentMatchRules() {
		
		let snapshot = matchRules
			?? (CM_Rules.shared.hasSessionOverride ? CM_Rules_Snapshot.fromCurrentRules() : nil)
		
		guard let snapshot else {
			CM_Alert_ViewController.present(CM_Multiplayer_Error.unknown(String(key: "network.lobby.rules.missing")))
			return
		}
		
		let controller = CM_Rules_ViewController(snapshot: snapshot)
		controller.title = String(key: "rules.title.network")
		present(CM_NavigationController(rootViewController: controller), animated: true)
	}
	
	public override func viewDidLoad() {
		
		super.viewDidLoad()
		
		if networkUserId == nil {
			networkUserId = CM_Multiplayer_Service.shared.currentUserId
		}
		
		startNetworkGameIfNeeded()
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		// Ne pas appeler la sélection d'adversaires du mode solo
	}
	
	public override func viewDidDisappear(_ animated: Bool) {
		
		super.viewDidDisappear(animated)
		
		guard isBeingDismissed || navigationController?.isBeingDismissed == true else { return }
		
		CM_Rules.shared.clearSessionRules()
		
		let roomId = networkRoomId
		
		if !isLeaving, let roomId {
			isLeaving = true
			let name = CM_Player.current.name ?? "?"
			CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
			Task {
				_ = try? await CM_Multiplayer_Service.shared.leaveNetworkGame(roomId: roomId, playerName: name)
			}
		} else if let roomId {
			CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
		}
	}
	
	private func startNetworkGameIfNeeded() {
		
		guard !didStart else { return }
		didStart = true
		
		guard let game = initialRoom.game else {
			
			CM_Alert_ViewController.present(CM_Multiplayer_Error.unknown(String(key: "network.error.gameMissing"))) {
				self.dismissPresentedNetworkFlow()
			}
			return
		}
		
		// Appliquer les règles de l'hôte pour toute la durée de la partie
		let sessionRules = matchRules ?? CM_Rules_Snapshot.fromCurrentRules()
		matchRules = sessionRules
		CM_Rules.shared.applySessionRules(sessionRules)
		beginNetworkMatch(from: game)
		
		let roomId = initialRoom.id
		CM_Multiplayer_Service.shared.listenToRoom(roomId: roomId) { [weak self] result in
			
			DispatchQueue.main.async {
				
				guard let self else { return }
				
				switch result {
				case .success(let updatedRoom):
					if let rules = updatedRoom.rules {
						self.matchRules = rules
						CM_Rules.shared.applySessionRules(rules)
					}
					if let state = updatedRoom.game {
						self.applyNetworkGameState(state)
					}
				case .failure:
					// Document supprimé : ne pas interrompre une alerte de victoire/défaite en cours
					guard !self.isLeaving else { return }
					CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
					
					if self.victoryHandled {
						return
					}
					
					self.isLeaving = true
					self.dismissPresentedNetworkFlow()
				}
			}
		}
	}
	
	public override func leaveNetworkGameAndDismiss() {
		
		isLeaving = true
		super.leaveNetworkGameAndDismiss()
	}
}
