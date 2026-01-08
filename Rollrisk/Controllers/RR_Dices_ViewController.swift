//
//  RR_Dices_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 07/01/2026.
//

import UIKit
import SnapKit

/// Mode de jeu multijoueur local - tous les joueurs sont humains
public class RR_Dices_ViewController : RR_Game_ViewController {
	
	public override func loadView() {
		
		super.loadView()
		
		// Activer le mode multijoueur local
		isLocalMultiplayer = true
		
		// Titre spécifique au mode multijoueur local
		title = String(key: "dices.title")
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		// Ne pas appeler super pour éviter l'alerte du mode solo
		// Appeler directement la logique de base de RR_ViewController
		
		showPlayersSelectionAlert()
	}
	
	private func showPlayersSelectionAlert() {
		
		let alertViewController: RR_Alert_ViewController = .init()
		alertViewController.backgroundView.isUserInteractionEnabled = false
		alertViewController.title = String(key: "dices.players.title")
		alertViewController.add(String(key: "dices.players.content"))
		
		(2...4).forEach { index in
			
			alertViewController.addButton(title: String(key: "dices.players.button.\(index)")) { [weak self] _ in
				
				alertViewController.close { [weak self] in
					
					self?.startLocalGame(numberOfPlayers: index)
				}
			}
		}
		
		alertViewController.addCancelButton { [weak self] _ in
			
			self?.dismiss()
		}
		
		alertViewController.present()
	}
	
	private func startLocalGame(numberOfPlayers: Int) {
		
		players.removeAll()
		
		// Créer les joueurs humains
		for i in 1...numberOfPlayers {
			
			let player: RR_Player = .init()
			player.name = String(key: "dices.player.default.name") + " \(i)"
			player.resetGameState()
			players.append(player)
		}
		
		// Demander les noms des joueurs
		askPlayerNames(startingAt: 0)
	}
	
	private func askPlayerNames(startingAt index: Int) {
		
		guard index < players.count else {
			// Tous les noms ont été saisis, démarrer le jeu
			startGame()
			return
		}
		
		let player = players[index]
		
		let alertViewController: RR_Alert_ViewController = .init()
		alertViewController.title = String(key: "dices.player.name.title") + " \(index + 1)"
		
		let textField = RR_TextField()
		textField.placeholder = player.name
		textField.autocapitalizationType = .words
		alertViewController.add(textField)
		
		alertViewController.addButton(title: String(key: "dices.player.name.button")) { [weak self] _ in
			
			if let name = textField.text, !name.isEmpty {
				player.name = name
			}
			
			alertViewController.close { [weak self] in
				self?.askPlayerNames(startingAt: index + 1)
			}
		}
		alertViewController.addCancelButton() { [weak self] _ in
			
			self?.dismiss()
		}
		alertViewController.present()
		
		// Focus sur le champ de texte
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			textField.becomeFirstResponder()
		}
	}
	
	private func startGame() {
		
		currentPlayerIndex = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		
		UIView.animation {
			self.stackView.alpha = 1.0
		}
		
		setupDice()
		updatePlayersDisplay()
		updateValidateButton()
		updateUIForCurrentPlayer()
		
		// Afficher qui commence
		showCurrentPlayerTutorial()
	}
	
	private func showCurrentPlayerTutorial() {
		
		let currentPlayer = players[currentPlayerIndex]
		
		let tutorial = RR_Tutorial_ViewController()
		tutorial.items = [
			RR_Tutorial_ViewController.Item(
				title: String(key: "dices.turn.title"),
				subtitle: currentPlayer.name,
				timeInterval: 1.5
			)
		]
		tutorial.present()
	}
	
	// Override pour afficher le nom du joueur actuel à chaque changement de tour
	override func nextPlayer() {
		
		super.nextPlayer()
		
		// Afficher qui doit jouer
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			self?.showCurrentPlayerTutorial()
		}
	}
}
