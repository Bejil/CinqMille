//
//  CM_Network_Lobby_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import UIKit
import SnapKit

public class CM_Network_Lobby_ViewController: CM_ViewController {
	
	private enum Mode {
		case home
		case lobby
	}
	
	private var mode:Mode = .home
	private var room:CM_Room?
	private var didPresentGame:Bool = false
	private var isLeaving:Bool = false
	
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = UI.Margins
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(UI.Margins)
		return $0
		
	}(UIStackView())
	
	private lazy var statusLabel:CM_Label = {
		
		$0.font = Fonts.Content.Text.Regular
		$0.textColor = Colors.Content.Text
		$0.textAlignment = .center
		$0.numberOfLines = 0
		return $0
		
	}(CM_Label())
	
	private lazy var codeLabel:CM_Label = {
		
		$0.font = Fonts.Content.Title.H2
		$0.textColor = Colors.Primary
		$0.textAlignment = .center
		return $0
		
	}(CM_Label())
	
	private lazy var qrCodeImageView:UIImageView = {
		
		$0.contentMode = .scaleAspectFit
		$0.backgroundColor = .white
		$0.layer.cornerRadius = UI.CornerRadius
		$0.clipsToBounds = true
		$0.snp.makeConstraints { make in
			make.width.height.equalTo(160)
		}
		return $0
		
	}(UIImageView())
	
	private lazy var qrHintLabel:CM_Label = {
		
		$0.font = Fonts.Content.Text.Regular
		$0.textColor = Colors.Content.Text
		$0.textAlignment = .center
		$0.numberOfLines = 0
		$0.text = String(key: "network.lobby.qr.hint")
		return $0
		
	}(CM_Label())
	
	private lazy var playersStackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = UI.Margins / 2
		return $0
		
	}(UIStackView())
	
	private lazy var createButton:CM_Button = .init(String(key: "network.lobby.create")) { [weak self] _ in
		self?.createRoom()
	}
	
	private lazy var joinButton:CM_Button = {
		
		$0.type = .secondary
		return $0
		
	}(CM_Button(String(key: "network.lobby.join")) { [weak self] _ in
		self?.promptJoinCode()
	})
	
	private lazy var joinWaitingButton:CM_Button = {
		
		$0.type = .tertiary
		return $0
		
	}(CM_Button(String(key: "network.lobby.joinWaiting")) { [weak self] _ in
		self?.joinWaitingRoomAutomatically()
	})
	
	private lazy var startButton:CM_Button = {
		
		$0.type = .secondary
		$0.isEnabled = false
		return $0
		
	}(CM_Button(String(key: "network.lobby.start")) { [weak self] _ in
		self?.startGame()
	})
	
	private lazy var rulesButton:CM_Button = {
		
		$0.type = .tertiary
		return $0
		
	}(CM_Button(String(key: "network.lobby.rules")) { [weak self] _ in
		self?.presentRoomRules()
	})
	
	private lazy var leaveButton:CM_Button = {
		
		$0.type = .tertiary
		return $0
		
	}(CM_Button(String(key: "network.lobby.leave")) { [weak self] _ in
		self?.leaveRoomAndClose()
	})
	
	public override func loadView() {
		
		super.loadView()
		
		isModal = true
		title = String(key: "network.lobby.title")
		
		let scrollView = CM_ScrollView()
		scrollView.showsVerticalScrollIndicator = false
		view.addSubview(scrollView)
		scrollView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide)
		}
		
		scrollView.addSubview(stackView)
		stackView.snp.makeConstraints { make in
			make.top.bottom.equalToSuperview()
			make.left.right.width.equalToSuperview()
		}
		
		showHome()
		cleanupFinishedRoomsInBackground()
	}
	
	public override func viewDidDisappear(_ animated: Bool) {
		
		super.viewDidDisappear(animated)
		
		// Ne pas quitter la room lors du passage lobby → partie (setViewControllers)
		guard isBeingDismissed || navigationController?.isBeingDismissed == true else { return }
		guard !isLeaving else { return }
		
		isLeaving = true
		let roomId = room?.id
		room = nil
		
		Task {
			if let roomId {
				CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
				try? await CM_Multiplayer_Service.shared.leaveRoom(roomId: roomId)
			}
		}
	}
	
	// MARK: - UI
	
	private func showHome() {
		
		mode = .home
		room = nil
		stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		
		statusLabel.text = String(key: "network.lobby.home.subtitle")
		stackView.addArrangedSubview(statusLabel)
		stackView.addArrangedSubview(createButton)
		stackView.addArrangedSubview(joinButton)
		stackView.addArrangedSubview(joinWaitingButton)
	}
	
	private func showLobby(_ room:CM_Room) {
		
		mode = .lobby
		self.room = room
		stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		
		statusLabel.text = String(key: "network.lobby.code.title")
		codeLabel.text = room.code
		qrCodeImageView.image = CM_QRCode.image(forCode: room.code)
		
		let qrContainer = UIStackView(arrangedSubviews: [qrCodeImageView, qrHintLabel])
		qrContainer.axis = .vertical
		qrContainer.spacing = UI.Margins / 2
		qrContainer.alignment = .center
		
		stackView.addArrangedSubview(statusLabel)
		stackView.addArrangedSubview(codeLabel)
		stackView.addArrangedSubview(qrContainer)
		stackView.addArrangedSubview(playersStackView)
		
		let userId = CM_Multiplayer_Service.shared.currentUserId
		if room.hostId == userId {
			stackView.addArrangedSubview(startButton)
		}
		
		stackView.addArrangedSubview(rulesButton)
		stackView.addArrangedSubview(leaveButton)
		updateLobbyContent(room)
	}
	
	private func updateLobbyContent(_ room:CM_Room) {
		
		self.room = room
		codeLabel.text = room.code
		
		playersStackView.arrangedSubviews.forEach {
			playersStackView.removeArrangedSubview($0)
			$0.removeFromSuperview()
		}
		
		for player in room.players {
			
			let row = CM_Label("\(player.name)\(player.isHost ? " ★" : "")")
			row.font = Fonts.Content.Text.Regular
			row.textColor = Colors.Content.Title
			row.textAlignment = .center
			playersStackView.addArrangedSubview(row)
		}
		
		let userId = CM_Multiplayer_Service.shared.currentUserId
		startButton.isEnabled = room.canStart && room.hostId == userId
		
		if room.status == .playing {
			statusLabel.text = String(key: "network.lobby.started")
			startButton.isEnabled = false
			presentNetworkGame(with: room)
		}
	}
	
	// MARK: - Actions
	
	private func playerDisplayName() -> String {
		
		if let name = CM_Player.current.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
			return name
		}
		return String(key: "dices.player.default.name")
	}
	
	private func createRoom() {
		
		createButton.isLoading = true
		
		Task { [weak self] in
			
			do {
				let room = try await CM_Multiplayer_Service.shared.createRoom(playerName: self?.playerDisplayName() ?? "?")
				await MainActor.run {
					self?.createButton.isLoading = false
					self?.showLobby(room)
					self?.startListening(roomId: room.id)
				}
			} catch {
				await MainActor.run {
					self?.createButton.isLoading = false
					CM_Alert_ViewController.present(error)
				}
			}
		}
	}
	
	private func promptJoinCode() {
		
		let alert = CM_Alert_ViewController()
		alert.title = String(key: "network.lobby.join.choice.title")
		alert.add(String(key: "network.lobby.join.choice.content"))
		
		alert.addButton(title: String(key: "network.lobby.join.choice.manual")) { [weak self] _ in
			alert.close {
				self?.promptManualJoinCode()
			}
		}
		alert.addButton(title: String(key: "network.lobby.join.choice.scan")) { [weak self] _ in
			alert.close {
				self?.presentQRCodeScanner()
			}
		}
		alert.addCancelButton()
		alert.present()
	}
	
	private func promptManualJoinCode() {
		
		let alert = CM_Alert_ViewController()
		alert.title = String(key: "network.lobby.join.title")
		alert.add(String(key: "network.lobby.join.content"))
		
		let textField = CM_TextField()
		textField.placeholder = String(key: "network.lobby.join.placeholder")
		textField.autocapitalizationType = .allCharacters
		textField.autocorrectionType = .no
		alert.add(textField)
		
		alert.addButton(title: String(key: "network.lobby.join.confirm")) { [weak self] _ in
			
			let code = textField.text ?? ""
			alert.close {
				self?.joinRoom(code: code)
			}
		}
		alert.addCancelButton()
		alert.present()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			textField.becomeFirstResponder()
		}
	}
	
	private func presentQRCodeScanner() {
		
		let scanner = CM_QRCode_Scanner_ViewController()
		scanner.onCodeScanned = { [weak self] code in
			self?.joinRoom(code: code)
		}
        UI.MainController.present(CM_NavigationController(rootViewController: scanner), animated: true)
	}
	
	private func joinWaitingRoomAutomatically() {
		
		joinWaitingButton.isLoading = true
		
		Task { [weak self] in
			
			do {
				_ = try? await CM_Multiplayer_Service.shared.cleanupFinishedRooms()
				let rooms = try await CM_Multiplayer_Service.shared.fetchWaitingRooms()
				
				guard let room = rooms.first else {
					await MainActor.run {
						self?.joinWaitingButton.isLoading = false
						CM_Alert_ViewController.present(CM_Multiplayer_Error.unknown(String(key: "network.lobby.joinWaiting.empty")))
					}
					return
				}
				
				let joined = try await CM_Multiplayer_Service.shared.joinRoom(
					code: room.code,
					playerName: self?.playerDisplayName() ?? "?"
				)
				
				await MainActor.run {
					self?.joinWaitingButton.isLoading = false
					self?.showLobby(joined)
					self?.startListening(roomId: joined.id)
				}
			} catch {
				await MainActor.run {
					self?.joinWaitingButton.isLoading = false
					CM_Alert_ViewController.present(error)
				}
			}
		}
	}
	
	private func cleanupFinishedRoomsInBackground() {
		
		Task {
			_ = try? await CM_Multiplayer_Service.shared.cleanupFinishedRooms()
		}
	}
	
	private func joinRoom(code:String) {
		
		joinButton.isLoading = true
		
		Task { [weak self] in
			
			do {
				let room = try await CM_Multiplayer_Service.shared.joinRoom(code: code, playerName: self?.playerDisplayName() ?? "?")
				await MainActor.run {
					self?.joinButton.isLoading = false
					self?.showLobby(room)
					self?.startListening(roomId: room.id)
				}
			} catch {
				await MainActor.run {
					self?.joinButton.isLoading = false
					CM_Alert_ViewController.present(error)
				}
			}
		}
	}
	
	private func presentRoomRules() {
		
		guard let snapshot = room?.rules else {
			CM_Alert_ViewController.present(CM_Multiplayer_Error.unknown(String(key: "network.lobby.rules.missing")))
			return
		}
		
		let controller = CM_Rules_ViewController(snapshot: snapshot)
		controller.title = String(key: "rules.title.network")
		present(CM_NavigationController(rootViewController: controller), animated: true)
	}
	
	private func startGame() {
		
		guard let room else { return }
		startButton.isLoading = true
		
		Task { [weak self] in
			
			do {
				try await CM_Multiplayer_Service.shared.startGame(roomId: room.id)
				await MainActor.run {
					self?.startButton.isLoading = false
					// La navigation se fait via le listener quand status == playing
				}
			} catch {
				await MainActor.run {
					self?.startButton.isLoading = false
					CM_Alert_ViewController.present(error)
				}
			}
		}
	}
	
	private func presentNetworkGame(with room:CM_Room) {
		
		guard !didPresentGame else { return }
		guard room.game != nil else { return }
		
		didPresentGame = true
		// Ne pas stopListening ici : la game VC reprend le listener.
		// Un stop ici + deinit lobby coupait la sync pour tous les joueurs.
		
		let gameController = CM_Network_Game_ViewController(room: room)
		navigationController?.setViewControllers([gameController], animated: true)
	}
	
	private func leaveRoomAndClose() {
		
		guard !isLeaving else { return }
		isLeaving = true
		
		let roomId = room?.id
		room = nil
		
		// Laisser le listener actif le temps d'écrire/supprimer n'est pas nécessaire pour soi,
		// mais la suppression doit arriver aux autres avant qu'on coupe tout.
		Task { [weak self] in
			
			if let roomId {
				try? await CM_Multiplayer_Service.shared.leaveRoom(roomId: roomId)
				CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
			}
			
			await MainActor.run {
				self?.dismissLobbyFlow()
			}
		}
	}
	
	private func handleLobbyCancelled() {
		
		guard !isLeaving else { return }
		isLeaving = true
		
		let roomId = room?.id
		room = nil
		
		if let roomId {
			CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
		}
		
		let alert = CM_Alert_ViewController()
		alert.title = String(key: "network.lobby.cancelled.title")
		alert.add(String(key: "network.lobby.cancelled.content"))
		alert.addDismissButton { [weak self] _ in
			self?.dismissLobbyFlow()
		}
		alert.present()
	}
	
	private func dismissLobbyFlow() {
		
		if let navigationController, navigationController.presentingViewController != nil {
			navigationController.dismiss(animated: true)
		} else {
			dismiss()
		}
	}
	
	private func startListening(roomId:String) {
		
		CM_Multiplayer_Service.shared.listenToRoom(roomId: roomId) { [weak self] result in
			
			DispatchQueue.main.async {
				
				guard let self else { return }
				
				switch result {
				case .success(let room):
					self.updateLobbyContent(room)
					if room.status == .playing {
						self.presentNetworkGame(with: room)
					}
				case .failure:
					// Document supprimé (hôte parti / partie annulée)
					self.handleLobbyCancelled()
				}
			}
		}
	}
}
