//
//  CM_Game_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class CM_Game_ViewController : CM_ViewController {
	
	private lazy var bannerView = CM_Ads.shared.presentBanner(Ads.Banner.Game, self)
	
	// MARK: - Mode de jeu
	
	/// Si true, tous les joueurs sont humains (pas d'IA)
	var isLocalMultiplayer: Bool = false
	
	/// Mode multijoueur réseau (Firebase)
	var isNetworkMultiplayer: Bool = false
	var networkRoomId: String?
	var networkUserId: String?
	var networkPlayerIds: [String] = []
	private var networkRevision: Int = 0
	private var networkEventId: Int = 0
	private var isApplyingRemoteState: Bool = false
	private var isPushingNetworkState: Bool = false
	private var pendingNetworkPush:(winnerId:String?, force:Bool, eventType:String?, eventMessage:String?)?
	private var networkPendingEventType:String?
	private var networkPendingEventMessage:String?
	private var pendingNetworkWinnerId:String?
	/// Fin du tour courant (timestamp Unix), synchronisée via Firestore
	private var networkTurnEndsAt:TimeInterval?
	private var networkTurnTimer:Timer?
	private var isForfeitingNetworkTurn:Bool = false
	
	/// Retourne true si le joueur actuel est un humain (localement contrôlable)
	func isCurrentPlayerHuman() -> Bool {
		if isNetworkMultiplayer {
			return isMyNetworkTurn()
		}
		if isLocalMultiplayer {
			return true // En mode multijoueur local, tous les joueurs sont humains
		}
		return currentPlayerIndex == 0 // En mode solo, seul le premier joueur est humain
	}
	
	func isMyNetworkTurn() -> Bool {
		
		guard isNetworkMultiplayer,
			  let userId = networkUserId,
			  currentPlayerIndex < networkPlayerIds.count else { return false }
		return networkPlayerIds[currentPlayerIndex] == userId
	}
	
	// MARK: - Propriétés de jeu
	
	var players:[CM_Player] = []
	var currentPlayerIndex:Int = 0
	var diceViews:[CM_Dice] = []
	var isRolling:Bool = false
	var turnScore:Int = 0
	var accumulatedScore:Int = 0 // Score accumulé des "bravo" précédents
	var hasRolledThisTurn:Bool = false
	var scoringDiceIndices:Set<Int> = []
	var currentRollNumber:Int = 0
	private var isAIPlaying:Bool = false // Indique si l'IA est en train de jouer
	private var aiTurnId:Int = 0 // Identifiant unique du tour IA pour annuler les appels asynchrones
	private var rollId:Int = 0 // Identifiant unique du lancer pour annuler les callbacks si interrompu
	private var isAutoPassing:Bool = false // Évite de déclencher plusieurs passes auto
	
	// MARK: - Dernier tour
	
	/// Indique si c'est le dernier tour (un joueur a atteint l'objectif)
	private var isLastRound:Bool = false
	/// Index du joueur qui a déclenché le dernier tour
	private var lastRoundTriggerPlayerIndex:Int? = nil
	/// Ensemble des joueurs qui ont déjà joué leur dernier tour
	private var playersWhoPlayedLastRound:Set<Int> = []
	/// Flag pour empêcher les appels multiples à handleVictory
	private(set) var victoryHandled:Bool = false
	lazy var stackView:UIStackView = {
		
		$0.alpha = 0.0
		$0.axis = .vertical
		$0.spacing = UI.Margins
		$0.addArrangedSubview(containerStackView)
		$0.addArrangedSubview(turnScoreStackView)
		return $0
		
	}(UIStackView())
	private lazy var containerStackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = UI.Margins
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(UI.Margins)
		return $0
		
	}(UIStackView(arrangedSubviews: [playersStackView, dicesStackView]))
	private lazy var playersStackView:UIStackView = {
		
		$0.axis = .horizontal
		$0.distribution = .fillEqually
		$0.spacing = UI.Margins/2
		return $0
		
	}(UIStackView())
	private lazy var dicesStackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = UI.Margins
		$0.backgroundColor = Colors.Secondary
		$0.layer.cornerRadius = UI.CornerRadius
		$0.layer.borderWidth = 2
		$0.layer.borderColor = Colors.Content.Text.withAlphaComponent(0.3).cgColor
		$0.clipsToBounds = false
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(UI.Margins)
		
		let selectedDiceContainerStackView:UIStackView = .init(arrangedSubviews: [selectedDiceStackView])
		selectedDiceContainerStackView.axis = .vertical
		selectedDiceContainerStackView.alignment = .center
		selectedDiceContainerStackView.addLine(position: .bottom)
		selectedDiceContainerStackView.isLayoutMarginsRelativeArrangement = true
		selectedDiceContainerStackView.layoutMargins.bottom = UI.Margins
		$0.addArrangedSubview(selectedDiceContainerStackView)
		
		$0.addArrangedSubview(diceContainerView)
		
		$0.addArrangedSubview(rollHintLabel)
		
		return $0
		
	}(UIStackView())
	private lazy var selectedDiceStackView:UIStackView = {
		
		$0.axis = .horizontal
		$0.distribution = .equalCentering
		$0.spacing = UI.Margins / 2
		$0.alignment = .center
		$0.isUserInteractionEnabled = true
		$0.snp.makeConstraints { make in
			make.height.equalTo(50)
		}
		
		$0.addSubview(selectedDicePlaceholderLabel)
		selectedDicePlaceholderLabel.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		
		return $0
		
	}(UIStackView())
	private lazy var selectedDicePlaceholderLabel:CM_Label = {
		
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(CM_Label(String(key: "game.selected.placeholder")))
	private lazy var diceContainerView:UIView = {
		
		$0.addGestureRecognizer(UITapGestureRecognizer(block: { [weak self] _ in
			
			self?.handleDiceTap()
		}))
		$0.addSubview(rollPlaceholderLabel)
		rollPlaceholderLabel.snp.makeConstraints { make in
			make.center.equalToSuperview()
			make.left.right.equalToSuperview().inset(UI.Margins)
		}
		return $0
		
	}(UIView())
	private lazy var rollHintLabel:CM_Label = {
		
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		$0.addLine(position: .top)
		$0.contentInsets.top = UI.Margins
		$0.isUserInteractionEnabled = true
		$0.addGestureRecognizer(UITapGestureRecognizer(block: { [weak self] _ in
			
			self?.handleDiceTap()
		}))
		return $0
		
	}(CM_Label(String(key: "game.roll.hint")))
	private lazy var rollPlaceholderLabel:CM_Label = {
		
		$0.font = Fonts.Content.Title.H4
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(CM_Label(String(key: "game.roll.hint")))
	private lazy var turnScoreStackView:UIStackView = {
		
		$0.axis = .horizontal
		$0.spacing = UI.Margins
		$0.alignment = .center
		$0.distribution = .fillEqually
		$0.layer.addSublayer(buttonsShapeLayer)
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(top: UI.Margins, left: UI.Margins, bottom: view.safeAreaInsets.bottom + UI.Margins, right: UI.Margins)
		$0.addArrangedSubview(scoreLabelsStackView)
		$0.addArrangedSubview(validateButton)
		return $0
		
	}(UIStackView())
	private lazy var scoreLabelsStackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = UI.Margins / 4
		$0.alignment = .center
		
		let turnScoreTitleLabel:CM_Label = .init(String(key: "game.turn.score"))
		turnScoreTitleLabel.font = Fonts.Content.Text.Regular
		turnScoreTitleLabel.textColor = Colors.Background.View
		turnScoreTitleLabel.textAlignment = .center
		$0.addArrangedSubview(turnScoreTitleLabel)
		
		$0.addArrangedSubview(turnScoreLabel)
		
		return $0
		
	}(UIStackView())
	private lazy var buttonsShapeLayer:CAShapeLayer = {
		
		$0.fillColor = Colors.Primary.cgColor
		$0.shadowOffset = .zero
		$0.shadowRadius = UI.CornerRadius
		$0.shadowOpacity = 0.25
		$0.masksToBounds = false
		$0.shadowColor = UIColor.black.cgColor
		return $0
		
	}(CAShapeLayer())
	lazy var turnScoreLabel:CM_Label = {
		
		$0.font = Fonts.Content.Title.H2
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(CM_Label("0"))
	private lazy var validateButton:CM_Button = {
		
		$0.isEnabled = false
		$0.type = .secondary
		return $0
		
	}(CM_Button(String(key: "game.validate")) { [weak self] _ in
		
		self?.handleValidateOrSkip()
	})
	
	private func handleValidateOrSkip() {
		
		// Vérifier si c'est le tour d'une IA (pas le joueur humain index 0)
		if !isCurrentPlayerHuman() {
			// Mode "Passer" - simuler que l'IA a joué et passer au joueur suivant
			skipAITurn()
		} else if isStuckDueToExactScore() {
			// Aucune sélection possible sans dépasser le score max : abandonner le tour
			passTurnDueToExactScore()
		} else {
			// Mode "Valider" - valider le tour du joueur humain
			validateTurn()
		}
	}
	
	private func skipAITurn() {
		
		// Vérifier que c'est bien le tour d'une IA
		guard !isCurrentPlayerHuman() else { return }
		
		// Arrêter l'IA en cours et invalider les appels asynchrones
		isAIPlaying = false
		aiTurnId += 1
		rollId += 1 // Invalider les callbacks de lancer en cours
		isRolling = false
		
		// Arrêter toutes les animations des dés
		for dice in diceViews {
			dice.layer.removeAllAnimations()
		}
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = CM_Rules.shared
		
		// Simuler le jeu de l'IA sans animation
		let simulatedScore = simulateAITurn()
		
		// Si l'IA a marqué des points valides, les ajouter
		if simulatedScore > 0 && simulatedScore < 99999 {
			// Vérifier les conditions de validation
			let canOpen = !rules.openingRequired || currentPlayer.hasOpened || simulatedScore >= rules.openingScore
			let potentialTotal = currentPlayer.score + simulatedScore
			let doesNotExceed = !rules.exactScore || potentialTotal <= rules.targetScore
			
			if canOpen && doesNotExceed {
				currentPlayer.scores.append(simulatedScore)
				
				if !currentPlayer.hasOpened && rules.openingRequired && simulatedScore >= rules.openingScore {
					currentPlayer.hasOpened = true
				}
				
				let newScore = currentPlayer.score
				updatePlayersDisplay()
				
				// Appliquer la règle d'égalité (avec callback pour attendre la fermeture du tutoriel)
				let continueAfterEquality = { [weak self] in
					guard let self = self else { return }
					
					// Vérifier si l'IA a atteint l'objectif
					if newScore >= rules.targetScore {
						
						// Gérer le dernier tour
						if !self.isLastRound {
							self.isLastRound = true
							self.lastRoundTriggerPlayerIndex = self.currentPlayerIndex
							self.playersWhoPlayedLastRound.insert(self.currentPlayerIndex)
							
							// Afficher le tutoriel "Dernier tour"
							self.showLastRoundTutorial {
								self.proceedAfterSkipAI()
							}
							return
						} else {
							self.playersWhoPlayedLastRound.insert(self.currentPlayerIndex)
							self.checkEndOfLastRound()
							return
						}
					}
					
					// Si on est dans le dernier tour mais l'IA n'a pas atteint l'objectif
					if self.isLastRound {
						self.playersWhoPlayedLastRound.insert(self.currentPlayerIndex)
						self.checkEndOfLastRound()
						return
					}
					
					// Continuer normalement
					self.proceedAfterSkipAI()
				}
				
				if rules.equalityKnockback {
					applyEqualityKnockback(for: currentPlayer, newScore: newScore, completion: continueAfterEquality)
				} else {
					continueAfterEquality()
				}
				return
			}
		}
		
		// Si on est dans le dernier tour
		if isLastRound {
			playersWhoPlayedLastRound.insert(currentPlayerIndex)
			
			// Réinitialiser l'état du tour
			hasRolledThisTurn = false
			scoringDiceIndices.removeAll()
			currentRollNumber = 0
			accumulatedScore = 0
			turnScore = 0
			turnScoreLabel.text = "0"
			resetDiceToContainer()
			updatePlayersDisplay()
			
			checkEndOfLastRound()
			return
		}
		
		proceedAfterSkipAI()
	}
	
	/// Continue après avoir passé le tour de l'IA
	private func proceedAfterSkipAI() {
		
		// Réinitialiser l'état du tour
		isRolling = false
		isAIPlaying = false
		hasRolledThisTurn = false
		scoringDiceIndices.removeAll()
		currentRollNumber = 0
		accumulatedScore = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		
		// Remettre tous les dés dans la stackview principale
		resetDiceToContainer()
		
		// Passer au joueur suivant
		currentPlayerIndex = (currentPlayerIndex + 1) % players.count
		updatePlayersDisplay()
		updateUIForCurrentPlayer()
		updateRollHint()
		
		// NE PAS relancer l'IA automatiquement ici
		// L'utilisateur doit appuyer sur "Passer" à nouveau ou attendre l'IA
		// Seulement si c'est le tour du joueur humain, on s'arrête
		if isCurrentPlayerHuman() {
			// C'est le tour du joueur humain - tout s'arrête
			isAIPlaying = false
		} else {
			// C'est encore une IA - lancer l'IA normalement
			playAI()
		}
	}
	
	/// Simule un tour complet de l'IA et retourne le score obtenu (0 si ballot)
	private func simulateAITurn() -> Int {
		
		let rules = CM_Rules.shared
		let currentPlayer = players[currentPlayerIndex]
		var totalScore = 0
		var remainingDice = rules.diceCount
		
		// Simuler plusieurs lancers jusqu'à validation ou ballot
		while remainingDice > 0 {
			// Lancer les dés virtuellement
			var values:[Int] = []
			for _ in 0..<remainingDice {
				values.append(Int.random(in: 1...6))
			}
			
			// Calculer le score de ce lancer
			let (score, scoringValues, instantWin) = calculateCombinationScore(for: values)
			
			// Victoire instantanée
			if instantWin {
				return 99999 // Score spécial pour victoire instantanée
			}
			
			// Ballot - perd tout
			if score == 0 {
				return 0
			}
			
			totalScore += score
			
			// Calculer les dés restants
			remainingDice -= scoringValues.count
			
			// Décider si l'IA continue ou valide
			if remainingDice == 0 {
				// Bravo ! Peut relancer tous les dés
				let ballotProbability = calculateBallotProbability(diceCount: rules.diceCount)
				
				// Si le score est élevé, sécuriser
				if totalScore >= 1000 || (ballotProbability * Double(totalScore) > 100) {
					return totalScore
				}
				
				// Sinon, relancer tous les dés
				remainingDice = rules.diceCount
			} else {
				// Décider de valider ou relancer
				let ballotProbability = calculateBallotProbability(diceCount: remainingDice)
				let riskThreshold = calculateRiskThreshold(
					turnScore: totalScore,
					currentScore: currentPlayer.score,
					targetScore: rules.targetScore,
					ballotProbability: ballotProbability
				)
				
				// Vérifier si on peut ouvrir
				if rules.openingRequired && !currentPlayer.hasOpened {
					if totalScore >= rules.openingScore {
						return totalScore // Ouvrir dès que possible
					}
					// Continuer à jouer pour atteindre le score d'ouverture
					continue
				}
				
				if totalScore >= riskThreshold {
					return totalScore // Valider
				}
				// Sinon continuer à jouer
			}
		}
		
		return totalScore
	}
	
	public override func loadView() {
		
		super.loadView()
		
		isModal = true
		title = String(key: "game.title")
		navigationItem.rightBarButtonItem = .init(customView: CM_Settings_Button())
		
		view.addSubview(stackView)
		stackView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
	}
	
	public override func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()
		
		let bezierPath = UIBezierPath()
		bezierPath.move(to: .init(x: 0, y: UI.Margins/2))
		bezierPath.addLine(to: .init(x: turnScoreStackView.frame.size.width, y: 0))
		bezierPath.addLine(to: .init(x: turnScoreStackView.frame.size.width, y: turnScoreStackView.frame.size.height))
		bezierPath.addLine(to: .init(x: 0, y: turnScoreStackView.frame.size.height))
		bezierPath.close()
		buttonsShapeLayer.path = bezierPath.cgPath
	}
	
	public override func close() {
		
		let alertController:CM_Alert_ViewController = .init()
		alertController.title = String(key: "game.close.alert.title")
		alertController.add(String(key: "game.close.alert.content"))
		let button = alertController.addButton(title: String(key: "game.close.alert.button")) { [weak self] _ in
			
			alertController.close { [weak self] in
				
				guard let self else { return }
				
				if self.isNetworkMultiplayer {
					self.leaveNetworkGameAndDismiss()
					return
				}
				
				if !self.isLocalMultiplayer {
					
					let currentPlayer = CM_Player.current
					currentPlayer.stats.abandonments += 1
					currentPlayer.save()
				}
				
				self.dismiss()
			}
		}
		button.type = .delete
		alertController.addCancelButton()
		alertController.present()
	}
	
	func leaveNetworkGameAndDismiss() {
		
		stopNetworkTurnTimer()
		
		guard let roomId = networkRoomId else {
			dismissPresentedNetworkFlow()
			return
		}
		
		var name = CM_Player.current.name ?? "?"
		if let userId = networkUserId,
		   let index = networkPlayerIds.firstIndex(of: userId),
		   index < players.count {
			name = players[index].name ?? name
		}
		
		// Couper le listener avant la suppression pour éviter l'alerte "partie introuvable"
		CM_Multiplayer_Service.shared.stopListening(roomId: roomId)
		
		Task { [weak self] in
			
			_ = try? await CM_Multiplayer_Service.shared.leaveNetworkGame(roomId: roomId, playerName: name)
			
			await MainActor.run {
				self?.dismissPresentedNetworkFlow()
			}
		}
	}
	
	/// Ferme le flux modal (NavigationController présenté), pas seulement le VC enfant.
	func dismissPresentedNetworkFlow() {
		
		stopNetworkTurnTimer()
		CM_Rules.shared.clearSessionRules()
		CM_Player.current.resetGameState()
		
		let afterDismiss = { [weak self] in
			
			CM_Alert_ViewController.presentLoading({ alertController in
				
				CM_Ads.shared.presentInterstitial(Ads.FullScreen.Game.End, nil, {
					
					alertController?.close {
						
						if CM_Ads.shared.shouldDisplayAd {
							
							CM_InAppPurchase.shared.promptInAppPurchaseAlert(withCapping: true)
						}
					}
				})
			})
			
			_ = self
		}
		
		if let navigationController, navigationController.presentingViewController != nil {
			navigationController.dismiss(animated: true, completion: afterDismiss)
		} else if presentingViewController != nil {
			dismiss(animated: true, completion: afterDismiss)
		} else {
			afterDismiss()
		}
	}
	
	public override func dismiss(_ completion: (() -> Void)? = nil) {
		
		CM_Player.current.resetGameState()
		
		let finish = {
			
			completion?()
			
			CM_Alert_ViewController.presentLoading({ alertController in
				
				CM_Ads.shared.presentInterstitial(Ads.FullScreen.Game.End, nil, {
				
					alertController?.close {
						
						if CM_Ads.shared.shouldDisplayAd {
							
							CM_InAppPurchase.shared.promptInAppPurchaseAlert(withCapping: true)
						}
					}
				})
			})
		}
		
		if let navigationController, navigationController.presentingViewController != nil {
			navigationController.dismiss(animated: true, completion: finish)
		} else {
			super.dismiss(animated: true, completion: finish)
		}
	}
	
	private func handleDiceTap() {
		
		guard !isRolling else { return }
		guard isCurrentPlayerHuman() else { return } // Seulement si c'est le tour d'un humain
		
		// Si on a déjà lancé, il faut avoir sélectionné au moins un dé pour relancer
		if hasRolledThisTurn {
			let hasLockedDice = diceViews.contains { $0.isLocked }
			guard hasLockedDice else { return }
		}
		
		rollDice()
	}
	
	private func rollDice() {
		
		isRolling = true
		
		// Incrémenter le rollId pour invalider les callbacks d'un éventuel lancer précédent
		rollId += 1
		let currentRollId = rollId
		
		// Relancer le décompte à chaque relance du même tour (pas au premier lancer)
		if isNetworkMultiplayer && isMyNetworkTurn() && !isApplyingRemoteState && hasRolledThisTurn {
			refreshNetworkTurnDeadline()
		}
		
		// Masquer les placeholders et hints pendant le lancer
		rollHintLabel.alpha = 0.0
		rollPlaceholderLabel.isHidden = true
		
		// Forcer le layout pour avoir les dimensions du conteneur
		view.layoutIfNeeded()
		
		// Incrémenter le numéro de lancer
		currentRollNumber += 1
		
		// Si tous les dés sont verrouillés, on les déverrouille tous pour relancer (bravo !)
		let allLocked = diceViews.allSatisfy { $0.isLocked }
		if allLocked {
			// Accumuler le score actuel avant de relancer
			accumulatedScore += turnScore
			
			// Remettre tous les dés dans le conteneur principal
			resetDiceToContainer()
		}
		
		let group = DispatchGroup()
		
		let dices = diceViews.filter({ !$0.isLocked })
		
		let key = CM_Audio.Sounds.RawValue(key: "Dice_\(dices.count)")
		if let sound = CM_Audio.Sounds(rawValue: key) {
			CM_Audio.shared.playSound(sound)
		}
		
		// Récupérer les positions des dés verrouillés qui restent dans le conteneur
		let lockedDicePositions = diceViews
			.filter { $0.isLocked && $0.superview == diceContainerView }
			.compactMap { $0.originalPosition }
		
		// Générer les positions finales aléatoires en évitant les dés verrouillés
		let finalPositions = generateRandomPositions(count: dices.count, avoiding: lockedDicePositions)
		
		// Positionner les dés au centre et les afficher
		let centerX = diceContainerView.bounds.midX - 25
		let centerY = diceContainerView.bounds.midY - 25
		
		for dice in dices {
			dice.isHidden = false
			positionDice(dice, at: CGPoint(x: centerX, y: centerY))
		}
		
		// Animer les dés vers leur position finale
		for (index, dice) in dices.enumerated() {
			
			group.enter()
			
			let finalPosition = finalPositions[index]
			
			// Sauvegarder la position finale comme position originale
			dice.originalPosition = finalPosition
			
			// Animation vers la position finale
			UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
				dice.frame.origin = finalPosition
			}
			
			// Animation de rotation du dé
			dice.roll {
				group.leave()
			}
		}
		
		group.notify(queue: .main) { [weak self] in
			
			guard let self = self else { return }
			
			// Ignorer si le lancer a été interrompu (tour passé)
			guard self.rollId == currentRollId else { return }
			
			self.isRolling = false
			self.calculateTurnScore()
			self.pushNetworkGameStateIfNeeded()
		}
	}
	
	private func calculateTurnScore() {
		
		hasRolledThisTurn = true
		
		// Récupérer les indices et valeurs des dés non verrouillés
		var unlockedDiceInfo:[(index:Int, value:Int)] = []
		for (index, dice) in diceViews.enumerated() where !dice.isLocked {
			unlockedDiceInfo.append((index, dice.value))
		}
		
		let values = unlockedDiceInfo.map { $0.value }
		let (score, scoringValues) = calculateScoreWithScoringDice(for: values)
		
		// Identifier les dés scorants parmi les non-verrouillés
		scoringDiceIndices.removeAll()
		var remainingScoringValues = scoringValues
		
		for info in unlockedDiceInfo {
			if let idx = remainingScoringValues.firstIndex(of: info.value) {
				scoringDiceIndices.insert(info.index)
				remainingScoringValues.remove(at: idx)
			}
		}
		
		// Vérifier si c'est un ballot (aucun dé scorant)
		let isBallot = (score == 0)
		
		if isBallot {
			// Ballot - perd tous les points du tour
			CM_Audio.shared.playSound(.Error)
			CM_Feedback.shared.make(.Off)
			
			turnScore = 0
			turnScoreLabel.text = "0"
			
			if isNetworkMultiplayer {
				stopNetworkTurnTimer()
			}
			
			animateBallot()
			pushNetworkGameStateIfNeeded(force: true, eventType: "ballot")
			
			// Après un ballot, réinitialiser pour le prochain tour
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
				self?.endTurn()
			}
		} else {
			
			// Mettre à jour l'affichage
			updateRollHint()
			updateValidateButton()
			
			// Afficher le tutoriel de sélection de dé si c'est le premier lancer et qu'il y a des dés scorants
			if isCurrentPlayerHuman() && !isNetworkMultiplayer && !scoringDiceIndices.isEmpty {
				showDiceSelectionTutorial()
			}
			
			pushNetworkGameStateIfNeeded()
		}
	}
	
	private func showDiceSelectionTutorial() {
		
		// Trouver le premier dé scorant pour le tutoriel
		guard let firstScoringIndex = scoringDiceIndices.first else { return }
		let scoringDice = diceViews[firstScoringIndex]
		
		let tutorial = CM_Tutorial_ViewController()
		tutorial.key = .diceSelectionTutorialShown
		tutorial.items = [
			CM_Tutorial_ViewController.Item(
				sourceView: scoringDice,
				title: String(key: "game.tutorial.selectDice.title"),
				subtitle: String(key: "game.tutorial.selectDice.subtitle"),
				button: String(key: "game.tutorial.selectDice.button"),
				closure: { [weak self] in
					guard let self = self else { return }
					
					// Sélectionner le dé
					scoringDice.isLocked = true
					scoringDice.lockedAtRoll = self.currentRollNumber
					
					CM_Audio.shared.playSound(.Tap)
					CM_Feedback.shared.make(.On)
					
					// Déplacer le dé vers la zone des dés sélectionnés
					self.moveDiceToCorrectStackView(scoringDice)
					
					// Mettre à jour le score
					self.updateSelectedDiceScore()
					self.updateRollHint()
				}
			)
		]
		tutorial.completion = { [weak self] in
			guard let self = self else { return }
			
			// Afficher le deuxième tutoriel pointant vers le dé maintenant dans la zone sélectionnée
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				guard let selectedDice = self.selectedDiceStackView.arrangedSubviews.first else { return }
				
				let tutorial2 = CM_Tutorial_ViewController()
				tutorial2.key = .selectedDiceTutorialShown
				tutorial2.items = [
					CM_Tutorial_ViewController.Item(
						sourceView: selectedDice,
						title: String(key: "game.tutorial.selectedArea.title"),
						subtitle: String(key: "game.tutorial.selectedArea.subtitle"),
						button: String(key: "game.tutorial.selectedArea.button")
					)
				]
				tutorial2.present()
			}
		}
		tutorial.present()
	}
	
	private func validateTurn() {
		
		guard canValidate() else { return }
		
		// Arrêter le décompte : la validation a eu lieu avant 0
		if isNetworkMultiplayer {
			stopNetworkTurnTimer()
		}
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = CM_Rules.shared
		
		// Ajouter le score du tour au tableau des scores
		currentPlayer.scores.append(turnScore)
		
		let newScore = currentPlayer.score
		
		// Marquer que le joueur a ouvert s'il ne l'avait pas encore fait
		if !currentPlayer.hasOpened {
			currentPlayer.hasOpened = true
		}
		
		// Mettre à jour l'affichage
		updatePlayersDisplay()
		
		// Appliquer la règle d'égalité si activée (avec callback pour attendre la fermeture du tutoriel)
		let continueAfterEquality = { [weak self] in
			guard let self = self else { return }
			self.handlePostValidation(currentPlayer: currentPlayer, newScore: newScore, rules: rules)
		}
		
		if rules.equalityKnockback {
			applyEqualityKnockback(for: currentPlayer, newScore: newScore, completion: continueAfterEquality)
		} else {
			continueAfterEquality()
		}
	}
	
	/// Continue la logique de validation après l'affichage éventuel du tutoriel d'égalité
	private func handlePostValidation(currentPlayer: CM_Player, newScore: Int, rules: CM_Rules) {
		
		// Vérifier si le joueur a atteint l'objectif
		if newScore >= rules.targetScore {
			
			// Si c'est le premier à atteindre l'objectif, déclencher le dernier tour
			if !isLastRound {
				isLastRound = true
				lastRoundTriggerPlayerIndex = currentPlayerIndex
				playersWhoPlayedLastRound.insert(currentPlayerIndex)
				
				// Afficher le tutoriel "Dernier tour"
				showLastRoundTutorial {
					// Réinitialiser le flag IA si c'était son tour
					if !self.isCurrentPlayerHuman() {
						self.isAIPlaying = false
					}
					// Passer au joueur suivant pour leur donner une chance
					self.nextPlayer()
				}
				return
			} else {
				// On est déjà dans le dernier tour
				playersWhoPlayedLastRound.insert(currentPlayerIndex)
				checkEndOfLastRound()
				return
			}
		}
		
		// Si on est dans le dernier tour mais le joueur n'a pas atteint l'objectif
		if isLastRound {
			playersWhoPlayedLastRound.insert(currentPlayerIndex)
			checkEndOfLastRound()
			return
		}
		
		// Réinitialiser le flag IA si c'était son tour
		if !isCurrentPlayerHuman() {
			isAIPlaying = false
		}
		
		// Passer au joueur suivant
		nextPlayer()
	}
	
	/// Applique la règle d'égalité : si un joueur atteint le même score qu'un autre, l'autre retombe à son score précédent
	/// Retourne true si un knockback a été appliqué (et un tutoriel affiché)
	@discardableResult
	private func applyEqualityKnockback(for currentPlayer:CM_Player, newScore:Int, completion: (() -> Void)? = nil) -> Bool {
		
		let rules = CM_Rules.shared
		var knocked:[(player:CM_Player, lostPoints:Int)] = []
		
		for player in players where player != currentPlayer {
			
			if player.score == newScore && !player.scores.isEmpty {
				// Le joueur perd son dernier score (retombe à son score précédent)
				let lastScore = player.scores.removeLast()
				
				// Si le joueur retombe à zéro, il doit à nouveau réaliser le score d'ouverture
				if rules.openingRequired && player.score == 0 {
					player.hasOpened = false
				}
				
				knocked.append((player, lastScore))
			}
		}
		
		guard let first = knocked.first else {
			completion?()
			return false
		}
		
		updatePlayersDisplay()
		
		// Synchroniser scores + splash chez les autres joueurs pendant l'affichage local
		if isNetworkMultiplayer && !isApplyingRemoteState,
		   let index = players.firstIndex(of: first.player),
		   index < networkPlayerIds.count {
			let mustReopen = rules.openingRequired && !first.player.hasOpened
			networkPendingEventType = "equality"
			networkPendingEventMessage = "\(networkPlayerIds[index])|\(mustReopen ? 1 : 0)|\(first.lostPoints)"
			pushNetworkGameStateIfNeeded(force: true)
		}
		
		showKnockbackNotification(player: first.player, lostPoints: first.lostPoints, completion: completion)
		return true
	}
	
	private func isLocalNetworkPlayer(_ player:CM_Player) -> Bool {
		
		guard isNetworkMultiplayer,
			  let userId = networkUserId,
			  let index = players.firstIndex(of: player),
			  index < networkPlayerIds.count else { return false }
		return networkPlayerIds[index] == userId
	}
	
	private func showKnockbackNotification(player:CM_Player, lostPoints:Int, completion: (() -> Void)? = nil) {
		
		// Vibration et son pour signaler le knockback
		CM_Audio.shared.playSound(.Error)
		CM_Feedback.shared.make(.On)
		
		let mustReopen = CM_Rules.shared.openingRequired && !player.hasOpened
		let isVictimLocal = isLocalNetworkPlayer(player) || (!isNetworkMultiplayer && player == players[currentPlayerIndex])
		let subtitle: String
		
		if mustReopen {
			subtitle = isVictimLocal
				? String(key: "game.equality.tutorial.subtitle.currentPlayer.reopen")
				: (player.name ?? "") + " " + String(key: "game.equality.tutorial.subtitle.player.reopen")
		} else {
			subtitle = isVictimLocal
				? String(key: "game.equality.tutorial.subtitle.currentPlayer")
				: (player.name ?? "") + " " + String(key: "game.equality.tutorial.subtitle.player")
		}
		
		let viewController:CM_Tutorial_ViewController = .init()
		viewController.items = [
			CM_Tutorial_ViewController.Item(
				title: String(key: "game.equality.tutorial.title"),
				subtitle: subtitle,
				timeInterval: 1.5
			)
		]
		viewController.completion = completion
		viewController.present()
	}
	
	private func presentRemoteEqualitySplash(eventMessage:String?) {
		
		guard let eventMessage, !eventMessage.isEmpty else {
			presentTransientSplash(title: String(key: "game.equality.tutorial.title"), duration: 1.5)
			return
		}
		
		let parts = eventMessage.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
		let knockedId = parts[safe: 0]
		let mustReopen = parts[safe: 1] == "1"
		let lostPoints = Int(parts[safe: 2] ?? "") ?? 0
		
		if let knockedId,
		   let index = networkPlayerIds.firstIndex(of: knockedId),
		   index < players.count {
			// Aligner hasOpened si le message indique une réouverture (état déjà appliqué sinon)
			if mustReopen {
				players[index].hasOpened = false
			}
			showKnockbackNotification(player: players[index], lostPoints: lostPoints)
			return
		}
		
		presentTransientSplash(title: String(key: "game.equality.tutorial.title"), duration: 1.5)
	}
	
	private func isLocalWinner(_ winner:CM_Player) -> Bool {
		
		if isNetworkMultiplayer {
			guard let userId = networkUserId,
				  let index = players.firstIndex(of: winner),
				  index < networkPlayerIds.count else { return false }
			return networkPlayerIds[index] == userId
		}
		
		return winner == CM_Player.current
	}
	
	private func handleVictory(for winner:CM_Player) {
		
		// Empêcher les appels multiples
		guard !victoryHandled else { return }
		victoryHandled = true
		
		stopNetworkTurnTimer()
		isAIPlaying = false
		
		// Réinitialiser l'état du dernier tour
		isLastRound = false
		lastRoundTriggerPlayerIndex = nil
		playersWhoPlayedLastRound.removeAll()
		
		let iWon = isLocalWinner(winner)
		
		// Multijoueur local / réseau : pas de stats solo
		if isLocalMultiplayer || isNetworkMultiplayer {
			
			if iWon {
				CM_Audio.shared.playSound(.Success)
				CM_Feedback.shared.make(.On)
			} else {
				CM_Audio.shared.playSound(.Error)
				CM_Feedback.shared.make(.Off)
			}
			
			// Seul le client qui gagne (ou qui constate la fin) pousse winnerId — pas pendant un apply distant
			if isNetworkMultiplayer,
			   !isApplyingRemoteState,
			   let index = players.firstIndex(of: winner),
			   index < networkPlayerIds.count {
				pushNetworkGameStateIfNeeded(winnerId: networkPlayerIds[index], force: true)
			}
		}
		// En mode solo, sauvegarder les stats du joueur
		else if iWon {
			
			CM_Audio.shared.playSound(.Success)
			CM_Feedback.shared.make(.On)
			
			let currentPlayer = CM_Player.current
			currentPlayer.stats.wins += 1
			currentPlayer.save()
		}
		else {
			
			CM_Audio.shared.playSound(.Error)
			CM_Feedback.shared.make(.Off)
			
			let currentPlayer = CM_Player.current
			currentPlayer.stats.losses += 1
			currentPlayer.save()
		}
		
		let alert = CM_Alert_ViewController()
		alert.backgroundView.isUserInteractionEnabled = false
		
		if iWon {
			alert.title = String(key: "game.victory.title")
			alert.add(String(key: "game.victory.content.currentPlayer"))
		} else {
			alert.title = String(key: "game.defeat.title")
			alert.add(String(format: String(key: "game.defeat.content"), winner.name ?? "?"))
		}
		
		alert.addButton(title: String(key: "game.victory.button")) { [weak self] _ in
			
			alert.close { [weak self] in
				
				CM_Confettis.stop()
				
				guard let self else { return }
				
				if self.isNetworkMultiplayer {
					self.leaveNetworkGameAndDismiss()
				} else {
					self.dismiss()
				}
			}
		}
		alert.present {
			
			if iWon {
				CM_Confettis.start()
			}
		}
	}
	
	/// Affiche le tutoriel "Dernier tour !" quand un joueur atteint l'objectif
	private func showLastRoundTutorial(completion: @escaping () -> Void) {
		
		CM_Audio.shared.playSound(.Success)
		CM_Feedback.shared.make(.On)
		
		if isNetworkMultiplayer && !isApplyingRemoteState {
			networkPendingEventType = "lastRound"
			networkPendingEventMessage = nil
			pushNetworkGameStateIfNeeded(force: true)
		}
		
		let viewController:CM_Tutorial_ViewController = .init()
		viewController.items = [
			CM_Tutorial_ViewController.Item(
				title: String(key: "game.lastRound.title"),
				subtitle: String(key: "game.lastRound.subtitle"),
				timeInterval: 2.0
			)
		]
		viewController.completion = completion
		viewController.present()
	}
	
	/// Vérifie si tous les joueurs ont joué leur dernier tour et détermine le gagnant
	private func checkEndOfLastRound() {
		
		// Vérifier si tous les joueurs ont joué leur dernier tour
		let allPlayersPlayed = players.indices.allSatisfy { playersWhoPlayedLastRound.contains($0) }
		
		if allPlayersPlayed {
			// Déterminer le gagnant (score le plus élevé)
			// En cas d'égalité, le premier à avoir atteint le score gagne (celui qui a déclenché le dernier tour)
			guard let winner = players.enumerated().max(by: { player1, player2 in
				if player1.element.score == player2.element.score {
					// En cas d'égalité, celui qui a déclenché le dernier tour gagne
					return player1.offset != lastRoundTriggerPlayerIndex
				}
				return player1.element.score < player2.element.score
			})?.element else { return }
			
			// Petit délai pour s'assurer que les tutoriels/alertes précédents sont fermés
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.handleVictory(for: winner)
			}
		} else {
			// Réinitialiser le flag IA si c'était son tour
			if !isCurrentPlayerHuman() {
				isAIPlaying = false
			}
			// Passer au joueur suivant
			nextPlayer()
		}
	}
	
	private func canValidate() -> Bool {
		
		guard turnScore > 0 else { return false }
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = CM_Rules.shared
		
		// Vérifier le score minimum d'ouverture
		if rules.openingRequired && !currentPlayer.hasOpened {
			if turnScore < rules.openingScore {
				return false
			}
		}
		
		// Vérifier le dépassement du score maximum
		let potentialScore = currentPlayer.score + turnScore
		
		if rules.exactScore {
			// Si le score dépasse l'objectif, on ne peut pas valider
			if potentialScore > rules.targetScore {
				return false
			}
		}
		
		return true
	}
	
	/// Vérifie si le score dépasserait l'objectif
	private func wouldExceedTarget() -> Bool {
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = CM_Rules.shared
		let potentialScore = currentPlayer.score + turnScore
		
		return rules.exactScore && potentialScore > rules.targetScore
	}
	
	private var isAutoPassEnabled:Bool {
		// Indisponible en multijoueur en ligne
		if isNetworkMultiplayer { return false }
		return (UserDefaults.get(.autoPassEnabled) as? Bool) ?? false
	}
	
	func updateValidateButton() {
		
		let title:String
		let type:CM_Button.ButtonType
		let enabled:Bool
		
		if isNetworkMultiplayer && !isMyNetworkTurn() {
			title = titleWithNetworkCountdown(String(key: "network.game.waiting"))
			type = .tertiary
			enabled = false
		} else if isCurrentPlayerHuman() {
			if isStuckDueToExactScore() {
				// Aucun coup possible sans dépasser : permettre de passer
				title = titleWithNetworkCountdown(String(key: "game.skip"))
				type = .tertiary
				enabled = true
				scheduleAutoPassIfNeeded()
			} else {
				title = titleWithNetworkCountdown(String(key: "game.validate"))
				type = .secondary
				enabled = canValidate()
			}
		} else {
			// Tour de l'IA - bouton "Passer" toujours actif
			title = String(key: "game.skip")
			type = .tertiary
			enabled = true
		}
		
		// Éviter de réappliquer le même état (sinon le bouton clignote pendant le tour des adversaires)
		if validateButton.title != title {
			validateButton.title = title
		}
		if validateButton.type != type {
			validateButton.type = type
		}
		if validateButton.isEnabled != enabled {
			validateButton.isEnabled = enabled
		}
	}
	
	/// Ajoute le décompte restant au titre du bouton (mode réseau uniquement)
	private func titleWithNetworkCountdown(_ base:String) -> String {
		
		guard isNetworkMultiplayer,
			  !victoryHandled,
			  let endsAt = networkTurnEndsAt else { return base }
		
		let remaining = max(0, Int(ceil(endsAt - Date().timeIntervalSince1970)))
		return "\(base) (\(remaining))"
	}
	
	/// Passe automatiquement le tour si l'option est activée et qu'aucun coup n'est possible
	private func scheduleAutoPassIfNeeded() {
		
		guard isAutoPassEnabled else { return }
		guard isStuckDueToExactScore() else { return }
		guard !isAutoPassing else { return }
		
		isAutoPassing = true
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
			guard let self = self else { return }
			self.isAutoPassing = false
			guard self.isAutoPassEnabled, self.isStuckDueToExactScore() else { return }
			self.passTurnDueToExactScore()
		}
	}
	
	/// Bloqué car tous les coups scorants feraient dépasser l'objectif (règle score exact)
	private func isStuckDueToExactScore() -> Bool {
		
		let rules = CM_Rules.shared
		guard rules.exactScore else { return false }
		guard hasRolledThisTurn else { return false }
		guard isCurrentPlayerHuman() else { return false }
		if canValidate() { return false }
		
		let unlockedScoring = scoringDiceIndices.filter { !diceViews[$0].isLocked }
		guard !unlockedScoring.isEmpty else { return false }
		
		let player = players[currentPlayerIndex]
		let availableDice = unlockedScoring.map { diceViews[$0] }
		let count = availableDice.count
		let baselineScore = calculateHypotheticalScore(selectingAdditionalDice: [])
		
		// Tester toutes les combinaisons possibles de dés scorants
		for mask in 1..<(1 << count) {
			
			var subset:[CM_Dice] = []
			for index in 0..<count where mask & (1 << index) != 0 {
				subset.append(availableDice[index])
			}
			
			let hypotheticalScore = calculateHypotheticalScore(selectingAdditionalDice: subset)
			if player.score + hypotheticalScore <= rules.targetScore && hypotheticalScore > baselineScore {
				return false
			}
		}
		
		return true
	}
	
	/// Abandonne le tour lorsqu'aucun coup n'est possible sans dépasser le score max
	private func passTurnDueToExactScore() {
		
		guard isStuckDueToExactScore() else { return }
		
		if isNetworkMultiplayer {
			stopNetworkTurnTimer()
		}
		
		CM_Audio.shared.playSound(.Tap)
		CM_Feedback.shared.make(.On)
		
		turnScore = 0
		turnScoreLabel.text = "0"
		endTurn()
	}
	
	/// Temps écoulé : tour perdu, aucun point comptabilisé, passage au joueur suivant
	private func forfeitNetworkTurnDueToTimeout() {
		
		guard isNetworkMultiplayer,
			  isMyNetworkTurn(),
			  !isApplyingRemoteState,
			  !victoryHandled,
			  !isForfeitingNetworkTurn else { return }
		
		isForfeitingNetworkTurn = true
		defer { isForfeitingNetworkTurn = false }
		
		stopNetworkTurnTimer()
		
		// Annuler un lancer / animations en cours
		rollId += 1
		isRolling = false
		isAIPlaying = false
		
		turnScore = 0
		accumulatedScore = 0
		turnScoreLabel.text = "0"
		scoringDiceIndices.removeAll()
		
		CM_Audio.shared.playSound(.Error)
		CM_Feedback.shared.make(.Off)
		
		networkPendingEventType = "timeout"
		networkPendingEventMessage = String(key: "network.game.timeout")
		
		endTurn()
	}
	
	private func endTurn() {
		
		// Réinitialiser pour le prochain joueur ou tour
		hasRolledThisTurn = false
		scoringDiceIndices.removeAll()
		currentRollNumber = 0
		accumulatedScore = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		
		// Remettre tous les dés dans la stackview principale
		resetDiceToContainer()
		
		updateValidateButton()
		updateRollHint()
		
		// Si on est dans le dernier tour, marquer que ce joueur a joué (même s'il a fait un ballot)
		if isLastRound {
			playersWhoPlayedLastRound.insert(currentPlayerIndex)
			checkEndOfLastRound()
			pushNetworkGameStateIfNeeded(force: true)
			return
		}
		
		// Passer au joueur suivant
		nextPlayer()
	}
	
	func nextPlayer() {
		
		// Capturer avant de changer d'index : c'est le joueur qui termine son tour qui doit pousser
		let shouldSyncNetwork = isNetworkMultiplayer && isMyNetworkTurn() && !isApplyingRemoteState
		
		// Réinitialiser l'état du tour
		hasRolledThisTurn = false
		scoringDiceIndices.removeAll()
		currentRollNumber = 0
		accumulatedScore = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		lastShownCombination = nil
		
		// Remettre tous les dés dans la stackview principale
		resetDiceToContainer()
		
		// Passer au joueur suivant
		currentPlayerIndex = (currentPlayerIndex + 1) % players.count
		
		// Le délai démarre après le splash « À vous » du joueur concerné
		if isNetworkMultiplayer && !isApplyingRemoteState {
			if isMyNetworkTurn() {
				stopNetworkTurnTimer()
			} else {
				networkTurnEndsAt = nil
				stopNetworkTurnTimer()
			}
		}
		
		updatePlayersDisplay()
		updateUIForCurrentPlayer()
		updateRollHint()
		
		if shouldSyncNetwork {
			pushNetworkGameStateIfNeeded(force: true)
		}
		
		// Si c'est un adversaire (IA), jouer automatiquement — pas en réseau
		if !isCurrentPlayerHuman() {
			if isNetworkMultiplayer {
				isAIPlaying = false
			} else {
				playAI()
			}
		} else {
			// C'est le tour du joueur humain - s'assurer que l'IA est arrêtée
			isAIPlaying = false
			if isNetworkMultiplayer && shouldSyncNetwork {
				presentYourTurnSplashAndStartTimer()
			}
		}
		
		bannerView.refresh()
	}
	
	// MARK: - AI
	
	private func playAI() {
		
		// Incrémenter l'identifiant de tour pour invalider les anciens appels asynchrones
		aiTurnId += 1
		let currentTurnId = aiTurnId
		
		// Passer auto : simuler l'appui sur "Passer" au lieu de jouer l'IA avec animations
		if isAutoPassEnabled {
			scheduleAutoSkipAI(turnId: currentTurnId)
			return
		}
		
		isAIPlaying = true
		
		// Délai avant le premier lancer de l'IA
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == currentTurnId else { return }
			self.aiRollDice(turnId: currentTurnId)
		}
	}
	
	/// Simule automatiquement l'appui sur "Passer" pour le tour d'un adversaire
	private func scheduleAutoSkipAI(turnId:Int) {
		
		guard !isAutoPassing else { return }
		
		isAutoPassing = true
		isAIPlaying = true
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
			guard let self = self else { return }
			self.isAutoPassing = false
			guard self.aiTurnId == turnId else { return }
			guard self.isAutoPassEnabled, !self.isCurrentPlayerHuman() else {
				// L'option a été désactivée pendant l'attente : jouer l'IA normalement
				if !self.isCurrentPlayerHuman() {
					self.isAIPlaying = true
					self.aiRollDice(turnId: turnId)
				}
				return
			}
			self.skipAITurn()
		}
	}
	
	private func aiRollDice(turnId:Int) {
		
		guard isAIPlaying && aiTurnId == turnId else { return }
		
		rollDice()
		
		// Après le lancer, l'IA décide quoi faire
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == turnId else { return }
			self.aiDecide(turnId: turnId)
		}
	}
	
	private func aiDecide(turnId:Int) {
		
		guard isAIPlaying && aiTurnId == turnId else { return }
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = CM_Rules.shared
		
		// Vérifier s'il y a des dés scorants à sélectionner
		let scoringDice = diceViews.enumerated().filter { scoringDiceIndices.contains($0.offset) && !$0.element.isLocked }
		
		guard !scoringDice.isEmpty else {
			// Ballot déjà géré dans calculateTurnScore
			return
		}
		
		// Filtrer les dés si on doit atteindre le score exact
		let diceToSelect: [CM_Dice]
		if rules.exactScore {
			diceToSelect = aiFilterDiceForExactScore(scoringDice: scoringDice.map { $0.element }, player: currentPlayer)
		} else {
			diceToSelect = scoringDice.map { $0.element }
		}
		
		// Si aucun dé ne peut être sélectionné sans dépasser, valider le tour
		guard !diceToSelect.isEmpty else {
			if canValidate() {
				validateTurn()
			} else {
				// Ne peut ni sélectionner ni valider - ballot forcé sera géré
				endTurn()
			}
			return
		}
		
		// Sélectionner les dés un par un avec un délai
		aiSelectDiceSequentially(diceToSelect: diceToSelect, turnId: turnId) { [weak self] in
			
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == turnId else { return }
			
			// Mise à jour du score AVANT de décider - le callback sera appelé après le tutoriel si affiché
			self.updateSelectedDiceScore { [weak self] in
				
				guard let self = self else { return }
				guard self.isAIPlaying && self.aiTurnId == turnId else { return }
				
				// Décider si on valide ou on relance APRÈS mise à jour du score
				let shouldValidate = self.aiShouldValidate(currentPlayer: currentPlayer, rules: rules)
				
				// Petit délai après le tutoriel avant de continuer
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
					
					guard let self = self else { return }
					guard self.isAIPlaying && self.aiTurnId == turnId else { return }
					
					if shouldValidate && self.canValidate() {
						// Valider le tour
						self.validateTurn()
					} else {
						// Continuer à jouer (relancer les dés non verrouillés ou tous si bravo)
						self.aiRollDice(turnId: turnId)
					}
				}
			}
		}
	}
	
	/// Sélectionne les dés un par un avec un délai entre chaque
	private func aiSelectDiceSequentially(diceToSelect:[CM_Dice], turnId:Int, completion:@escaping ()->Void) {
		
		guard !diceToSelect.isEmpty else {
			completion()
			return
		}
		
		guard isAIPlaying && aiTurnId == turnId else { return }
		
		var remainingDice = diceToSelect
		let dice = remainingDice.removeFirst()
		
		// Sélectionner ce dé
		dice.isLocked = true
		dice.lockedAtRoll = currentRollNumber
		
		CM_Audio.shared.playSound(.Tap)
		CM_Feedback.shared.make(.On)
		
		// Déplacer le dé vers la stackview des dés sélectionnés
		moveDiceToCorrectStackView(dice)
		
		// Délai avant le prochain dé
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == turnId else { return }
			
			self.aiSelectDiceSequentially(diceToSelect: remainingDice, turnId: turnId, completion: completion)
		}
	}
	
	/// Choisit le meilleur sous-ensemble de dés scorants sans dépasser le score cible.
	/// Priorité : score exact > se rapprocher au maximum > plus de dés (bravo possible).
	private func aiFilterDiceForExactScore(scoringDice:[CM_Dice], player:CM_Player) -> [CM_Dice] {
		
		let rules = CM_Rules.shared
		let targetScore = rules.targetScore
		let pointsRemaining = targetScore - player.score
		
		// Loin de l'objectif : tout prendre
		if pointsRemaining > 2000 {
			return scoringDice
		}
		
		let baselineScore = calculateHypotheticalScore(selectingAdditionalDice: [])
		
		// Déjà au-dessus avec les dés verrouillés : ne rien ajouter
		if player.score + baselineScore > targetScore {
			return []
		}
		
		let count = scoringDice.count
		guard count > 0 else { return [] }
		
		var bestSubset:[CM_Dice] = []
		var bestTurnScore = baselineScore
		var bestIsExact = false
		
		// Explorer tous les sous-ensembles non vides (≤ 6 dés scorants en pratique)
		for mask in 1..<(1 << count) {
			
			var subset:[CM_Dice] = []
			subset.reserveCapacity(count)
			for index in 0..<count where mask & (1 << index) != 0 {
				subset.append(scoringDice[index])
			}
			
			let turnScore = calculateHypotheticalScore(selectingAdditionalDice: subset)
			let total = player.score + turnScore
			
			// Doit progresser et ne pas dépasser
			guard turnScore > baselineScore, total <= targetScore else { continue }
			
			let isExact = total == targetScore
			
			if isExact && !bestIsExact {
				bestSubset = subset
				bestTurnScore = turnScore
				bestIsExact = true
				continue
			}
			
			guard isExact == bestIsExact else { continue }
			
			if turnScore > bestTurnScore ||
				(turnScore == bestTurnScore && subset.count > bestSubset.count) {
				bestSubset = subset
				bestTurnScore = turnScore
			}
		}
		
		return bestSubset
	}
	
	private func aiShouldValidate(currentPlayer:CM_Player, rules:CM_Rules) -> Bool {
		
		let unlockedCount = diceViews.filter { !$0.isLocked }.count
		let potentialScore = currentPlayer.score + turnScore
		
		// Si on atteint exactement l'objectif, valider !
		if potentialScore == rules.targetScore {
			return true
		}
		
		// Si on dépasserait l'objectif (et exactScore est activé), ne pas valider
		// On doit relancer pour essayer de faire moins
		if rules.exactScore && potentialScore > rules.targetScore {
			return false // Continuer à jouer pour ajuster
		}
		
		// L'IA doit d'abord ouvrir - cas particulier
		let needsToOpen = rules.openingRequired && !currentPlayer.hasOpened
		
		if needsToOpen {
			if turnScore >= rules.openingScore {
				// On a assez pour ouvrir !
				// MAIS si c'est un bravo (tous les dés sélectionnés), on peut relancer sans risque
				if unlockedCount == 0 {
					// Bravo avec ouverture atteinte - relancer pour scorer plus !
					// Seulement ~3-8% de chances de ballot avec 5-6 dés
					return false
				}
				// Sinon, valider pour sécuriser l'ouverture
				return true
			}
			// Pas assez pour ouvrir : doit continuer à jouer, même avec peu de dés
			return false
		}
		
		// ==========================================
		// À PARTIR D'ICI, L'IA A DÉJÀ OUVERT
		// Elle peut donc être plus prudente
		// ==========================================
		
		// Probabilités de faire un ballot selon le nombre de dés restants
		// 1 dé : ~66% de ballot (4/6 chances de ne rien faire)
		// 2 dés : ~44% de ballot
		// 3 dés : ~28% de ballot
		// 4 dés : ~16% de ballot
		// 5 dés : ~8% de ballot
		// 6 dés : ~3% de ballot
		
		// Règle stricte : avec 1 ou 2 dés restants et un score décent, VALIDER
		// C'est trop risqué de relancer avec si peu de dés
		if unlockedCount == 1 && turnScore >= 100 {
			return true // 66% de chances de tout perdre, pas la peine
		}
		
		if unlockedCount == 2 && turnScore >= 200 {
			return true // 44% de chances de tout perdre
		}
		
		// CAS BRAVO : Tous les dés sont verrouillés, on peut tout relancer !
		// Statistiquement avec 5-6 dés, seulement ~3-8% de chances de ballot
		// C'est une EXCELLENTE opportunité de scorer plus !
		if unlockedCount == 0 {
			
			// Si le score permet de finir la partie, sécuriser
			if potentialScore >= rules.targetScore {
				return true
			}
			
			// Sinon, décider en fonction de la progression
			let progressRatio = Double(currentPlayer.score) / Double(rules.targetScore)
			
			// Proche de la victoire (>80%) ET score très élevé : sécuriser
			if progressRatio > 0.8 && turnScore >= 1500 {
				return true
			}
			
			// Score vraiment énorme (2000+) : sécuriser dans tous les cas
			if turnScore >= 2000 {
				return true
			}
			
			// SINON : TOUJOURS RELANCER !
			// Avec 5-6 dés, seulement ~3-8% de chances de ballot
			// L'espérance de gain est très positive
			return false
		}
		
		// Pour 3+ dés restants, utiliser le calcul de risque standard
		let ballotProbability = calculateBallotProbability(diceCount: unlockedCount)
		
		// Score en jeu vs risque
		let riskThreshold = calculateRiskThreshold(
			turnScore: turnScore,
			currentScore: currentPlayer.score,
			targetScore: rules.targetScore,
			ballotProbability: ballotProbability
		)
		
		// Décision basée sur le seuil de risque
		return turnScore >= riskThreshold
	}
	
	/// Calcule la probabilité approximative de faire un ballot
	private func calculateBallotProbability(diceCount:Int) -> Double {
		
		// Probabilité de ne pas scorer avec un dé = 4/6 (2, 3, 4, 6)
		// Probabilité de ballot = tous les dés ne scorent pas
		let noScoreProbability = 4.0 / 6.0
		return pow(noScoreProbability, Double(diceCount))
	}
	
	/// Calcule le seuil de score à partir duquel l'IA devrait valider
	private func calculateRiskThreshold(turnScore:Int, currentScore:Int, targetScore:Int, ballotProbability:Double) -> Int {
		
		let remainingToWin = targetScore - currentScore
		let progressRatio = Double(currentScore) / Double(targetScore)
		
		// Plus on est proche de la victoire, plus on est prudent
		// Plus le risque de ballot est élevé, plus on valide tôt
		
		// Seuil de base selon le risque de ballot
		var threshold:Int
		
		if ballotProbability > 0.5 {
			// Très risqué (1 dé) - valider dès 200 points
			threshold = 200
		} else if ballotProbability > 0.35 {
			// Risqué (2 dés) - valider dès 300 points
			threshold = 300
		} else if ballotProbability > 0.2 {
			// Modéré (3 dés) - valider dès 400 points
			threshold = 400
		} else if ballotProbability > 0.1 {
			// Faible risque (4 dés) - valider dès 500 points
			threshold = 500
		} else {
			// Très faible risque (5+ dés) - prendre des risques
			threshold = 600
		}
		
		// Ajuster selon la progression dans la partie
		if progressRatio > 0.8 {
			// Proche de la victoire, être plus prudent
			threshold = max(200, threshold - 100)
		} else if progressRatio < 0.2 {
			// Début de partie, prendre plus de risques
			threshold = threshold + 100
		}
		
		// Si le tour permettrait d'atteindre un bon pourcentage de l'objectif
		if turnScore > remainingToWin / 2 {
			// Valider car c'est une bonne avancée
			threshold = min(threshold, turnScore)
		}
		
		return threshold
	}
	
	private func calculateScoreWithScoringDice(for values:[Int]) -> (score:Int, scoringValues:[Int]) {
		
		let result = calculateCombinationScore(for: values)
		return (result.score, result.scoringValues)
	}
	
	private func calculateCombinationScore(for values:[Int]) -> (score:Int, scoringValues:[Int], instantWin:Bool) {
		
		guard !values.isEmpty else { return (0, [], false) }
		
		let rules = CM_Rules.shared
		var counts = [Int:Int]()
		
		for value in values {
			counts[value, default: 0] += 1
		}
		
		// Vérifier victoire instantanée (5 × 1 ou 5 × 5)
		if rules.fiveOnesWin && (counts[1] ?? 0) >= 5 {
			return (0, values, true)
		}
		if rules.fiveFivesWin && (counts[5] ?? 0) >= 5 {
			return (0, values, true)
		}
		
		// Suite 1-2-3-4-5-6 (seulement avec 6 dés)
		if values.count == 6 {
			let sortedUnique = Set(values)
			if sortedUnique == Set([1, 2, 3, 4, 5, 6]) {
				return (1500, values, false)
			}
		}
		
		// Suite 1-2-3-4-5 (avec 5 dés)
		if values.count == 5 {
			let sortedUnique = Set(values)
			if sortedUnique == Set([1, 2, 3, 4, 5]) {
				return (500, values, false)
			}
			if sortedUnique == Set([2, 3, 4, 5, 6]) {
				return (750, values, false)
			}
		}
		
		// Trois paires (6 dés)
		if values.count == 6 {
			let pairCount = counts.values.filter { $0 == 2 }.count
			if pairCount == 3 {
				return (750, values, false)
			}
		}
		
		// Deux brelans (6 dés)
		if values.count == 6 {
			let brelanCount = counts.values.filter { $0 >= 3 }.count
			if brelanCount == 2 {
				return (2500, values, false)
			}
		}
		
		// Full (brelan + paire) - seulement si activé dans les règles
		if rules.fullEnabled && values.count == 5 {
			let hasBrelan = counts.values.contains(3)
			let hasPair = counts.values.contains(2)
			if hasBrelan && hasPair {
				return (1250, values, false)
			}
		}
		
		// Calcul standard : brelans, carrés, etc. + dés individuels
		var score = 0
		var scoringValues:[Int] = []
		var remainingCounts = counts
		
		// D'abord les brelans et plus
		for (value, count) in counts {
			
			if count >= 3 {
				
				// Brelan de base
				if value == 1 {
					score += 1000
				} else {
					score += value * 100
				}
				
				// Multiplicateur pour carré, cinq, six identiques
				let extraDice = count - 3
				if extraDice >= 1 {
					// Carré = brelan × 2, Cinq = brelan × 4, Six = brelan × 8
					let multiplier = Int(pow(2.0, Double(extraDice)))
					if value == 1 {
						score += 1000 * (multiplier - 1)
					} else {
						score += value * 100 * (multiplier - 1)
					}
				}
				
				// Tous les dés du brelan+ sont scorants
				for _ in 0..<count {
					scoringValues.append(value)
				}
				remainingCounts[value] = 0
			}
		}
		
		// Ensuite les dés individuels (1 et 5 uniquement)
		for (value, count) in remainingCounts {
			
			if value == 1 {
				score += count * 100
				for _ in 0..<count {
					scoringValues.append(value)
				}
			} else if value == 5 {
				score += count * 50
				for _ in 0..<count {
					scoringValues.append(value)
				}
			}
		}
		
		// Appliquer la règle "multiple de 100 uniquement"
		if rules.multipleOf100Only {
			score = (score / 100) * 100
		}
		
		return (score, scoringValues, false)
	}
	
	private func animateBallot() {
		
		presentTransientSplash(title: String(key: "game.ballot"), duration: 0.5)
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		super.viewWillAppear(animated)
					
		let alertViewController:CM_Alert_ViewController = .init()
		alertViewController.backgroundView.isUserInteractionEnabled = false
		alertViewController.title = String(key: "game.opponents.title")
		alertViewController.add(String(key: "game.opponents.content"))
		(1...3).forEach { index in
			
			alertViewController.addButton(title: String(key: "game.opponents.button.\(index)")) { [weak self] _ in
				
				alertViewController.close { [weak self] in
					
					self?.start(for: index)
				}
			}
		}
		alertViewController.addCancelButton { [weak self] _ in
			
			self?.dismiss()
		}
		
		alertViewController.present()
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		
		super.viewDidAppear(animated)
		becomeFirstResponder()
	}
	
	public override var canBecomeFirstResponder: Bool {
		return true
	}
	
	public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		
		guard motion == .motionShake else { return }
		handleDiceTap()
	}
	
	private func start(for numberOfOpponents:Int) {
		
		players.removeAll()
		
		// Réinitialiser le joueur courant
		CM_Player.current.resetGameState()
		
		players.append(CM_Player.current)
		
		for i in 1...numberOfOpponents {
			
			let player:CM_Player = .init()
			player.name = String(key: "game.opponents.default.name") + " \(i)"
			players.append(player)
		}
		
		currentPlayerIndex = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		
		// Réinitialiser l'état du dernier tour
		isLastRound = false
		lastRoundTriggerPlayerIndex = nil
		playersWhoPlayedLastRound.removeAll()
		victoryHandled = false
		
		UIView.animation {
			
			self.stackView.alpha = 1.0
			self.containerStackView.addArrangedSubview(self.bannerView)
		}
		
		setupDice()
		updatePlayersDisplay()
		updateValidateButton()
		updateUIForCurrentPlayer()
		
		// Afficher le tutoriel pour les nouveaux joueurs
		showGameTutorial()
	}
	
	private func showGameTutorial() {
		
		let tutorial = CM_Tutorial_ViewController()
		tutorial.key = .gameTutorialShown
		tutorial.items = [
			CM_Tutorial_ViewController.Item(
				sourceView: playersStackView.arrangedSubviews.first,
				title: String(key: "game.tutorial.players.title"),
				subtitle: String(key: "game.tutorial.players.subtitle"),
				button: String(key: "game.tutorial.players.button")
			),
			CM_Tutorial_ViewController.Item(
				sourceView: scoreLabelsStackView,
				title: String(key: "game.tutorial.score.title"),
				subtitle: String(key: "game.tutorial.score.subtitle"),
				button: String(key: "game.tutorial.score.button")
			),
			CM_Tutorial_ViewController.Item(
				sourceView: validateButton,
				title: String(key: "game.tutorial.validate.title"),
				subtitle: String(key: "game.tutorial.validate.subtitle"),
				button: String(key: "game.tutorial.validate.button")
			)
		]
		tutorial.present()
	}
	
	func updateUIForCurrentPlayer() {
		
		diceContainerView.isUserInteractionEnabled = isCurrentPlayerHuman()
		updateValidateButton()
	}
	
	func setupDice() {
		
		// Remove existing dice
		diceViews.forEach { $0.removeFromSuperview() }
		diceViews.removeAll()
		
		// Reset state
		hasRolledThisTurn = false
		scoringDiceIndices.removeAll()
		currentRollNumber = 0
		accumulatedScore = 0
		
		let diceCount = CM_Rules.shared.diceCount
		
		for _ in 0..<diceCount {
			
			let dice = CM_Dice()
			dice.value = Int.random(in: 1...6)
			dice.isHidden = true // Masqué jusqu'au premier lancer
			diceContainerView.addSubview(dice)
			diceViews.append(dice)
			
			// Tap sur un dé pour le verrouiller/déverrouiller
			let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDiceLockTap(_:)))
			dice.addGestureRecognizer(tapGesture)
			dice.isUserInteractionEnabled = true
		}
		
		updateRollHint()
	}
	
	@objc private func handleDiceLockTap(_ gesture:UITapGestureRecognizer) {
		
		guard !isRolling else { return }
		guard !isAIPlaying else { return } // Bloquer si c'est l'IA qui joue
		guard isCurrentPlayerHuman() else { return } // Seulement si c'est le tour d'un humain
		guard let dice = gesture.view as? CM_Dice else { return }
		guard let diceIndex = diceViews.firstIndex(of: dice) else { return }
		
		// Vérifier si le dé peut être sélectionné/désélectionné
		if dice.isLocked {
			// Ne peut déverrouiller que les dés verrouillés lors du lancer actuel
			guard dice.lockedAtRoll == currentRollNumber else {
				showDiceSelectionError(dice)
				return
			}
		} else {
			// Ne peut verrouiller que les dés qui rapportent des points
			guard scoringDiceIndices.contains(diceIndex) else {
				showDiceSelectionError(dice)
				return
			}
			
			// Vérifier si la sélection ne ferait pas dépasser le score max
			if CM_Rules.shared.exactScore {
				let hypotheticalScore = calculateHypotheticalScore(selectingDice: dice)
				let potentialTotal = players[currentPlayerIndex].score + hypotheticalScore
				
				if potentialTotal > CM_Rules.shared.targetScore {
					showDiceSelectionError(dice)
					deselectCurrentRollDice()
					showExceedScoreTutorial()
					return
				}
			}
		}
		
		dice.isLocked.toggle()
		
		// Assigner ou retirer le numéro de lancer
		if dice.isLocked {
			dice.lockedAtRoll = currentRollNumber
		} else {
			dice.lockedAtRoll = nil
		}
		
		CM_Audio.shared.playSound(.Tap)
		CM_Feedback.shared.make(.On)
		
		// Animation de déplacement du dé
		moveDiceToCorrectStackView(dice)
		
		// Recalculer le score total des dés sélectionnés
		updateSelectedDiceScore()
		
		// Mettre à jour le hint
		updateRollHint()
		
		pushNetworkGameStateIfNeeded()
	}
	
	/// Déplace un dé vers la bonne stackview (sélectionnés ou à lancer)
	private func moveDiceToCorrectStackView(_ dice:CM_Dice) {
		
		// Sauvegarder la position actuelle si dans le conteneur
		let currentFrame = dice.frame
		
		// Animation de déplacement
		UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
			
			dice.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
			dice.alpha = 0.5
			
		} completion: { [weak self] _ in
			
			guard let self = self else { return }
			
			// Retirer du parent actuel
			self.selectedDiceStackView.removeArrangedSubview(dice)
			dice.removeFromSuperview()
			
			// Remettre la transformation à l'identité
			dice.transform = .identity
			
			if dice.isLocked {
				// Ajouter à la stackview des dés sélectionnés
				dice.translatesAutoresizingMaskIntoConstraints = false
				self.selectedDiceStackView.addArrangedSubview(dice)
				
				// Remettre les contraintes pour la stackview
				dice.snp.remakeConstraints { make in
					make.width.height.equalTo(50)
				}
			} else {
				// Remettre dans le conteneur principal
				self.diceContainerView.addSubview(dice)
				
				// Utiliser le frame directement (pas Auto Layout)
				dice.snp.removeConstraints()
				dice.translatesAutoresizingMaskIntoConstraints = true
				
				// Restaurer la position originale
				let position = dice.originalPosition ?? CGPoint(x: currentFrame.origin.x, y: currentFrame.origin.y)
				dice.frame = CGRect(x: position.x, y: position.y, width: 50, height: 50)
			}
			
			// Animation de réapparition
			UIView.animate(withDuration: 0.2) {
				dice.alpha = 1.0
			}
			
			// Mettre à jour la visibilité du placeholder
			self.updateSelectedDicePlaceholder()
		}
	}
	
	/// Met à jour la visibilité du placeholder selon s'il y a des dés sélectionnés
	private func updateSelectedDicePlaceholder() {
		
		let hasSelectedDice = !selectedDiceStackView.arrangedSubviews.isEmpty
		selectedDicePlaceholderLabel.isHidden = hasSelectedDice
	}
	
	/// Remet tous les dés dans la stackview principale (déverrouillés)
	private func resetDiceToContainer() {
		
		// Position centrale
		let centerX = diceContainerView.bounds.midX - 25
		let centerY = diceContainerView.bounds.midY - 25
		
		// Déverrouiller tous les dés
		for dice in diceViews {
			dice.isLocked = false
			dice.lockedAtRoll = nil
			dice.transform = .identity
			dice.isHidden = true
			dice.originalPosition = nil
		}
		
		// Retirer tous les dés de la stackview des dés sélectionnés
		for subview in selectedDiceStackView.arrangedSubviews {
			selectedDiceStackView.removeArrangedSubview(subview)
			subview.removeFromSuperview()
		}
		
		// Remettre tous les dés dans le conteneur principal (masqués, au centre)
		for dice in diceViews {
			dice.removeFromSuperview()
			dice.snp.removeConstraints()
			dice.translatesAutoresizingMaskIntoConstraints = true
			diceContainerView.addSubview(dice)
			dice.frame = CGRect(x: centerX, y: centerY, width: 50, height: 50)
		}
		
		// Afficher le placeholder car aucun dé n'est sélectionné
		updateSelectedDicePlaceholder()
	}
	
	/// Génère des positions aléatoires sans chevauchement pour les dés
	private func generateRandomPositions(count:Int, avoiding existingPositions:[CGPoint] = []) -> [CGPoint] {
		
		let containerBounds = diceContainerView.bounds
		let diceSize:CGFloat = 50
		let margin:CGFloat = 10
		let minDistance:CGFloat = diceSize + 10 // Espacement minimum entre les dés
		
		var positions:[CGPoint] = []
		
		// Combiner les positions existantes à éviter avec les nouvelles positions générées
		var allPositionsToAvoid = existingPositions
		
		let maxX = max(margin, containerBounds.width - diceSize - margin)
		let maxY = max(margin, containerBounds.height - diceSize - margin)
		
		for _ in 0..<count {
			var attempts = 0
			var position:CGPoint
			var isValid = false
			
			repeat {
				position = CGPoint(
					x: CGFloat.random(in: margin...maxX),
					y: CGFloat.random(in: margin...maxY)
				)
				
				// Vérifier qu'on ne chevauche pas les positions existantes ni les nouvelles positions
				isValid = !allPositionsToAvoid.contains { existing in
					let dx = position.x - existing.x
					let dy = position.y - existing.y
					return sqrt(dx*dx + dy*dy) < minDistance
				}
				
				attempts += 1
			} while !isValid && attempts < 100
			
			positions.append(position)
			allPositionsToAvoid.append(position)
		}
		
		return positions
	}
	
	/// Positionne un dé à une position donnée dans le conteneur
	private func positionDice(_ dice:CM_Dice, at position:CGPoint) {
		
		// Retirer les contraintes SnapKit et utiliser le frame
		dice.snp.removeConstraints()
		dice.translatesAutoresizingMaskIntoConstraints = true
		dice.frame = CGRect(x: position.x, y: position.y, width: 50, height: 50)
	}
	
	private func updateSelectedDiceScore(completion:(()->Void)? = nil) {
		
		// Grouper les dés verrouillés par numéro de lancer
		var diceByRoll:[Int:[Int]] = [:]
		
		for dice in diceViews where dice.isLocked {
			if let rollNumber = dice.lockedAtRoll {
				diceByRoll[rollNumber, default: []].append(dice.value)
			}
		}
		
		// Calculer le score pour chaque groupe de lancer séparément
		var currentRollsScore = 0
		var hasInstantWin = false
		var detectedCombinations:[String] = []
		
		for (_, values) in diceByRoll {
			let result = calculateCombinationScore(for: values)
			currentRollsScore += result.score
			if result.instantWin {
				hasInstantWin = true
			}
			
			// Détecter les combinaisons pour le tutoriel
			if let combinationName = detectCombinationName(for: values) {
				detectedCombinations.append(combinationName)
			}
		}
		
		// Ajouter le score accumulé des "bravo" précédents
		turnScore = accumulatedScore + currentRollsScore
		turnScoreLabel.text = "\(turnScore)"
		
		// Mettre à jour l'état du bouton valider
		updateValidateButton()
		
		// Afficher un tutoriel si une combinaison est détectée (une seule fois par combo)
		if !detectedCombinations.isEmpty {
			let combinationKey = detectedCombinations.joined(separator: "-")
			if combinationKey != lastShownCombination {
				if isNetworkMultiplayer {
					pushNetworkGameStateIfNeeded(
						eventType: "combination",
						eventMessage: detectedCombinations.joined(separator: "\n")
					)
				}
				showCombinationTutorial(combinations: detectedCombinations, completion: completion)
			} else {
				completion?()
			}
		} else {
			completion?()
		}
		
		// Vérifier victoire instantanée
		if hasInstantWin {
			handleInstantWin()
		}
	}
	
	/// Calcule le score hypothétique si on sélectionnait un dé supplémentaire
	private func calculateHypotheticalScore(selectingDice:CM_Dice) -> Int {
		
		return calculateHypotheticalScore(selectingAdditionalDice: [selectingDice])
	}
	
	/// Calcule le score hypothétique si on sélectionnait des dés supplémentaires
	private func calculateHypotheticalScore(selectingAdditionalDice additionalDice:[CM_Dice]) -> Int {
		
		var diceByRoll:[Int:[Int]] = [:]
		
		// Ajouter les dés déjà verrouillés
		for dice in diceViews where dice.isLocked {
			if let rollNumber = dice.lockedAtRoll {
				diceByRoll[rollNumber, default: []].append(dice.value)
			}
		}
		
		// Ajouter les dés qu'on veut sélectionner
		for dice in additionalDice {
			diceByRoll[currentRollNumber, default: []].append(dice.value)
		}
		
		var hypotheticalScore = 0
		
		for (_, values) in diceByRoll {
			let result = calculateCombinationScore(for: values)
			hypotheticalScore += result.score
		}
		
		return accumulatedScore + hypotheticalScore
	}
	
	/// Affiche une erreur de sélection de dé (shake + son)
	private func showDiceSelectionError(_ dice:CM_Dice) {
		
		CM_Feedback.shared.make(.Error)
		
		// Animation de refus
		let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
		animation.timingFunction = CAMediaTimingFunction(name: .linear)
		animation.duration = 0.3
		animation.values = [-5, 5, -5, 5, 0]
		dice.layer.add(animation, forKey: "shake")
	}
	
	/// Flag pour éviter d'afficher le tutoriel de dépassement plusieurs fois
	private var exceedScoreTutorialShown:Bool = false
	
	/// Désélectionne les dés verrouillés lors du lancer actuel
	private func deselectCurrentRollDice() {
		
		let diceToDeselect = diceViews.filter { $0.isLocked && $0.lockedAtRoll == currentRollNumber }
		guard !diceToDeselect.isEmpty else { return }
		
		for dice in diceToDeselect {
			dice.isLocked = false
			dice.lockedAtRoll = nil
			moveDiceToCorrectStackView(dice)
		}
		
		updateSelectedDiceScore()
		updateRollHint()
	}
	
	/// Affiche un tutoriel expliquant que le dé ferait dépasser le score maximum
	private func showExceedScoreTutorial() {
		
		// Ne pas afficher si déjà montré ce tour
		guard !exceedScoreTutorialShown else { return }
		exceedScoreTutorialShown = true
		
		let viewController:CM_Tutorial_ViewController = .init()
		viewController.items = [
			CM_Tutorial_ViewController.Item(
				title: String(key: "game.exceedScore.tutorial.title"),
				subtitle: String(key: "game.exceedScore.tutorial.subtitle"),
				timeInterval: 2.5
			)
		]
		viewController.completion = { [weak self] in
			self?.exceedScoreTutorialShown = false
		}
		viewController.present()
	}
	
	/// Détecte le nom de la combinaison formée par les dés
	private func detectCombinationName(for values:[Int]) -> String? {
		
		guard values.count >= 3 else { return nil }
		
		let rules = CM_Rules.shared
		var counts = [Int:Int]()
		
		for value in values {
			counts[value, default: 0] += 1
		}
		
		// Victoire instantanée (5 × 1 ou 5 × 5)
		if rules.fiveOnesWin && (counts[1] ?? 0) >= 5 {
			return String(key: "game.combination.fiveOnes")
		}
		if rules.fiveFivesWin && (counts[5] ?? 0) >= 5 {
			return String(key: "game.combination.fiveFives")
		}
		
		// Suite 1-2-3-4-5-6
		if values.count == 6 {
			let sortedUnique = Set(values)
			if sortedUnique == Set([1, 2, 3, 4, 5, 6]) {
				return String(key: "game.combination.straight")
			}
		}
		
		// Suite 1-2-3-4-5 ou 2-3-4-5-6
		if values.count == 5 {
			let sortedUnique = Set(values)
			if sortedUnique == Set([1, 2, 3, 4, 5]) || sortedUnique == Set([2, 3, 4, 5, 6]) {
				return String(key: "game.combination.smallStraight")
			}
		}
		
		// Trois paires
		if values.count == 6 {
			let pairCount = counts.values.filter { $0 == 2 }.count
			if pairCount == 3 {
				return String(key: "game.combination.threePairs")
			}
		}
		
		// Deux brelans
		if values.count == 6 {
			let brelanCount = counts.values.filter { $0 >= 3 }.count
			if brelanCount == 2 {
				return String(key: "game.combination.twoBrelan")
			}
		}
		
		// Full (brelan + paire)
		if rules.fullEnabled && values.count == 5 {
			let hasBrelan = counts.values.contains(3)
			let hasPair = counts.values.contains(2)
			if hasBrelan && hasPair {
				return String(key: "game.combination.fullHouse")
			}
		}
		
		// Six identiques
		for (value, count) in counts {
			if count == 6 {
				return String(format: String(key: "game.combination.sixOfAKind"), value)
			}
		}
		
		// Cinq identiques
		for (value, count) in counts {
			if count == 5 {
				return String(format: String(key: "game.combination.fiveOfAKind"), value)
			}
		}
		
		// Carré
		for (value, count) in counts {
			if count == 4 {
				return String(format: String(key: "game.combination.fourOfAKind"), value)
			}
		}
		
		// Brelan
		for (value, count) in counts {
			if count == 3 {
				return String(format: String(key: "game.combination.threeOfAKind"), value)
			}
		}
		
		return nil
	}
	
	private var lastShownCombination:String?
	private weak var activeSplashTutorial:CM_Tutorial_ViewController?
	
	private func showCombinationTutorial(combinations:[String], completion:(()->Void)? = nil) {
		
		// Ne montrer qu'une seule fois par combinaison
		let combinationKey = combinations.joined(separator: "-")
		guard combinationKey != lastShownCombination else {
			completion?()
			return
		}
		lastShownCombination = combinationKey
		
		presentTransientSplash(
			title: combinations.joined(separator: "\n"),
			duration: 1.5,
			completion: completion
		)
	}
	
	private func presentTransientSplash(title:String, duration:TimeInterval, completion:(()->Void)? = nil) {
		
		let presentNew = { [weak self] in
			
			guard let self else {
				completion?()
				return
			}
			
			let viewController:CM_Tutorial_ViewController = .init()
			viewController.items = [
				CM_Tutorial_ViewController.Item(
					title: title,
					timeInterval: duration
				)
			]
			viewController.completion = { [weak self] in
				if self?.activeSplashTutorial === viewController {
					self?.activeSplashTutorial = nil
				}
				completion?()
			}
			self.activeSplashTutorial = viewController
			viewController.present()
		}
		
		// Évite l'empilement de splashs qui bloque l'interface
		if let active = activeSplashTutorial {
			activeSplashTutorial = nil
			active.dismiss(animated: false) {
				presentNew()
			}
		} else {
			presentNew()
		}
	}
	
	private func handleInstantWin() {
		
		handleVictory(for: players[currentPlayerIndex])
	}
	
	private func updateRollHint() {
		
		// Observateur réseau : ne pas écraser la disposition synchronisée des dés
		if isNetworkMultiplayer && !isMyNetworkTurn() {
			rollHintLabel.alpha = 0.0
			rollPlaceholderLabel.isHidden = true
			setUnlockedDiceVisible(hasRolledThisTurn)
			return
		}
		
		// Ne rien afficher si c'est le tour de l'IA
		guard isCurrentPlayerHuman() else {
			rollHintLabel.alpha = 0.0
			rollPlaceholderLabel.isHidden = true
			setUnlockedDiceVisible(true)
			return
		}
		
		let hasLockedDice = diceViews.contains { $0.isLocked }
		let hasUnlockedDice = diceViews.contains { !$0.isLocked }
		let allDiceLocked = hasLockedDice && !hasUnlockedDice
		let canRollAllDice = !hasRolledThisTurn || allDiceLocked
		
		if canRollAllDice {
			// Afficher le placeholder au centre, masquer les dés
			setUnlockedDiceVisible(false)
			rollPlaceholderLabel.isHidden = false
			rollHintLabel.alpha = 1.0
			
			if allDiceLocked {
				rollPlaceholderLabel.text = String(key: "game.reroll.all.hint")
				rollHintLabel.text = String(key: "game.reroll.all.hint")
			} else {
				rollPlaceholderLabel.text = String(key: "game.roll.hint")
				rollHintLabel.text = String(key: "game.roll.hint")
			}
		} else if hasLockedDice && hasUnlockedDice {
			// Des dés à lancer, afficher les dés et le hint en bas
			setUnlockedDiceVisible(true)
			rollPlaceholderLabel.isHidden = true
			rollHintLabel.text = String(key: "game.reroll.hint")
			rollHintLabel.alpha = 1.0
		} else {
			// Dés visibles, sélection en cours
			setUnlockedDiceVisible(true)
			rollPlaceholderLabel.isHidden = true
			rollHintLabel.text = String(key: "game.select.hint")
			rollHintLabel.alpha = 1.0
		}
	}
	
	/// Affiche ou masque les dés non verrouillés dans le conteneur
	private func setUnlockedDiceVisible(_ visible:Bool) {
		
		for dice in diceViews where !dice.isLocked && dice.superview == diceContainerView {
			dice.isHidden = !visible
		}
	}
	
	func updatePlayersDisplay() {
		
		playersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		
		for (index, player) in players.enumerated() {
			
			let playerStackView = createPlayerStackView(
				player: player,
				isCurrentPlayer: index == currentPlayerIndex,
				isLocalPlayer: isLocalPlayerAtIndex(index)
			)
			playersStackView.addArrangedSubview(playerStackView)
		}
	}
	
	/// Joueur « vous » : solo vs IA et en ligne — pas en multijoueur local (même appareil)
	private func isLocalPlayerAtIndex(_ index:Int) -> Bool {
		
		guard index < players.count else { return false }
		
		// Multijoueur local : tous partagent l'écran, aucune distinction
		if isLocalMultiplayer && !isNetworkMultiplayer {
			return false
		}
		
		if isNetworkMultiplayer {
			guard let userId = networkUserId, index < networkPlayerIds.count else { return false }
			return networkPlayerIds[index] == userId
		}
		
		// Solo : le joueur humain
		return players[index] === CM_Player.current || index == 0
	}
	
	private func createPlayerStackView(player:CM_Player, isCurrentPlayer:Bool, isLocalPlayer:Bool) -> UIStackView {
		
		// Actif : même style pour tout le monde (cadre primaire)
		// Inactif : même style, mais moi sans opacité réduite
		
		let nameLabel:CM_Label = .init(player.name)
		nameLabel.font = Fonts.Content.Title.H4
		nameLabel.textColor = isCurrentPlayer ? Colors.Primary : Colors.Content.Title
		nameLabel.textAlignment = .center
		nameLabel.numberOfLines = 1
		nameLabel.adjustsFontSizeToFitWidth = true
		nameLabel.minimumScaleFactor = 0.5
		
		let scoreLabel:CM_Label = .init("\(player.score)")
		scoreLabel.font = Fonts.Content.Title.H4.withSize(Fonts.Content.Title.H4.pointSize - 4)
		scoreLabel.textColor = isCurrentPlayer ? Colors.Primary : Colors.Content.Text
		scoreLabel.textAlignment = .center
		
		let stackView:UIStackView = .init(arrangedSubviews: [nameLabel, scoreLabel])
		stackView.axis = .vertical
		stackView.spacing = UI.Margins/2
		stackView.alignment = .center
		stackView.layer.cornerRadius = UI.CornerRadius
		stackView.isLayoutMarginsRelativeArrangement = true
		stackView.layoutMargins = .init(UI.Margins)
		
		if isCurrentPlayer {
			stackView.backgroundColor = Colors.Primary.withAlphaComponent(0.28)
			stackView.layer.borderWidth = 3
			stackView.layer.borderColor = Colors.Primary.cgColor
		} else {
			stackView.backgroundColor = Colors.Content.Title.withAlphaComponent(0.06)
			stackView.layer.borderWidth = 0
			if !isLocalPlayer {
				stackView.alpha = 0.7
			}
		}
		
		// Tap pour voir les scores détaillés
		stackView.isUserInteractionEnabled = true
		let tapGesture = PlayerTapGestureRecognizer(target: self, action: #selector(handlePlayerTap(_:)))
		tapGesture.player = player
		stackView.addGestureRecognizer(tapGesture)
		
		return stackView
	}
	
	@objc private func handlePlayerTap(_ gesture:PlayerTapGestureRecognizer) {
		
		guard let player = gesture.player else { return }
		
		showPlayerScores(player: player)
	}
	
	private func showPlayerScores(player:CM_Player) {
		
		let alertViewController:CM_Alert_ViewController = .init()
		alertViewController.title = player.name ?? String(key: "game.player.scores.title")
		
		if player.scores.isEmpty {
			
			alertViewController.add(String(key: "game.player.scores.empty"))
		}
		else {
			
			var scoresText:[String] = .init()
			
			for (index, score) in player.scores.enumerated() {
				
				
				scoresText.append(String(key: "game.player.scores.turn") + " \(index + 1): \(score) pts")
			}
			
			alertViewController.add(scoresText.joined(separator: "\n"))
		}
		
		let totalLabel = alertViewController.add(String(key: "game.player.scores.total") + ": \(player.score) pts")
		totalLabel.font = Fonts.Content.Text.Bold
		
		alertViewController.addDismissButton()
		alertViewController.present()
	}
	
	// MARK: - Network sync
	
	func beginNetworkMatch(from state:CM_Game_State) {
		
		if networkUserId == nil {
			networkUserId = CM_Multiplayer_Service.shared.currentUserId
		}
		
		networkPlayerIds = state.players.map(\.id)
		players = state.players.map { remote in
			let player = CM_Player()
			player.name = remote.name
			player.scores = remote.scores
			player.hasOpened = remote.hasOpened
			return player
		}
		
		currentPlayerIndex = state.currentPlayerIndex
		turnScore = 0
		turnScoreLabel.text = "0"
		networkRevision = 0
		networkEventId = 0
		
		stackView.alpha = 1.0
		containerStackView.addArrangedSubview(bannerView)
		
		setupDice()
		applyNetworkGameState(state)
		updateUIForCurrentPlayer()
		updateRollHint()
		
		if isMyNetworkTurn() {
			DispatchQueue.main.async { [weak self] in
				self?.presentYourTurnSplashAndStartTimer()
			}
		}
	}
	
	/// Splash « À vous » puis démarrage du timer de tour (réseau)
	private func presentYourTurnSplashAndStartTimer() {
		
		guard isNetworkMultiplayer,
			  isMyNetworkTurn(),
			  !victoryHandled,
			  !isApplyingRemoteState else { return }
		
		stopNetworkTurnTimer()
		
		presentTransientSplash(title: String(key: "game.yourTurn"), duration: 1.5) { [weak self] in
			guard let self, self.isMyNetworkTurn(), !self.victoryHandled else { return }
			self.refreshNetworkTurnDeadline()
			self.pushNetworkGameStateIfNeeded(force: true)
		}
	}
	
	func makeNetworkGameState(winnerId:String? = nil) -> CM_Game_State {
		
		let playerStates = zip(players, networkPlayerIds).map { player, networkId in
			CM_Game_Player_State(
				id: networkId,
				name: player.name ?? "?",
				scores: player.scores,
				hasOpened: player.hasOpened
			)
		}
		
		let diceStates = diceViews.map {
			CM_Game_Die_State(value: $0.value, isLocked: $0.isLocked, lockedAtRoll: $0.lockedAtRoll)
		}
		
		networkRevision += 1
		
		var eventType = networkPendingEventType
		var eventMessage = networkPendingEventMessage
		var eventId = networkEventId
		
		if eventType != nil {
			eventId += 1
			networkEventId = eventId
		}
		
		networkPendingEventType = nil
		networkPendingEventMessage = nil
		
		return CM_Game_State(
			revision: networkRevision,
			currentPlayerIndex: currentPlayerIndex,
			players: playerStates,
			turnScore: turnScore,
			accumulatedScore: accumulatedScore,
			hasRolledThisTurn: hasRolledThisTurn,
			currentRollNumber: currentRollNumber,
			scoringDiceIndices: Array(scoringDiceIndices).sorted(),
			dice: diceStates,
			isLastRound: isLastRound,
			lastRoundTriggerPlayerIndex: lastRoundTriggerPlayerIndex,
			playersWhoPlayedLastRound: Array(playersWhoPlayedLastRound).sorted(),
			winnerId: winnerId,
			status: winnerId == nil ? "playing" : "finished",
			eventType: eventType,
			eventMessage: eventMessage,
			eventId: eventId,
			turnEndsAt: networkTurnEndsAt
		)
	}
	
	// MARK: - Network turn timer
	
	private func refreshNetworkTurnDeadline() {
		
		networkTurnEndsAt = Date().timeIntervalSince1970 + CM_Game_State.networkTurnDuration
		startNetworkTurnTimer()
	}
	
	private func startNetworkTurnTimer() {
		
		stopNetworkTurnTimer(clearDeadline: false)
		
		guard isNetworkMultiplayer,
			  !victoryHandled,
			  networkTurnEndsAt != nil else {
			updateValidateButton()
			return
		}
		
		updateValidateButton()
		
		let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
			self?.tickNetworkTurnTimer()
		}
		RunLoop.main.add(timer, forMode: .common)
		networkTurnTimer = timer
		
		// Vérifier immédiatement (ex. état distant déjà expiré)
		tickNetworkTurnTimer()
	}
	
	private func stopNetworkTurnTimer(clearDeadline:Bool = true) {
		
		networkTurnTimer?.invalidate()
		networkTurnTimer = nil
		if clearDeadline {
			networkTurnEndsAt = nil
		}
	}
	
	private func tickNetworkTurnTimer() {
		
		guard isNetworkMultiplayer, !victoryHandled else {
			stopNetworkTurnTimer()
			return
		}
		
		guard let endsAt = networkTurnEndsAt else {
			updateValidateButton()
			return
		}
		
		let remaining = endsAt - Date().timeIntervalSince1970
		updateValidateButton()
		
		guard remaining <= 0 else { return }
		
		if isMyNetworkTurn() {
			// Pendant un apply distant, laisser le timer tourner : le forfait partira au tick suivant
			guard !isApplyingRemoteState else { return }
			forfeitNetworkTurnDueToTimeout()
		} else {
			// Spectateur : garder l'affichage à 0 jusqu'à la synchro
			stopNetworkTurnTimer(clearDeadline: false)
		}
	}
	
	func pushNetworkGameStateIfNeeded(winnerId:String? = nil,
									  force:Bool = false,
									  eventType:String? = nil,
									  eventMessage:String? = nil) {
		
		guard isNetworkMultiplayer,
			  !isApplyingRemoteState,
			  let roomId = networkRoomId else { return }
		
		guard force || isMyNetworkTurn() else { return }
		
		if let eventType {
			networkPendingEventType = eventType
			networkPendingEventMessage = eventMessage
		}
		
		if isPushingNetworkState {
			let mergedForce = force || (pendingNetworkPush?.force ?? false)
			pendingNetworkPush = (
				winnerId ?? pendingNetworkPush?.winnerId,
				mergedForce,
				eventType ?? pendingNetworkPush?.eventType,
				eventMessage ?? pendingNetworkPush?.eventMessage
			)
			return
		}
		
		isPushingNetworkState = true
		let state = makeNetworkGameState(winnerId: winnerId)
		
		Task { [weak self] in
			
			do {
				try await CM_Multiplayer_Service.shared.updateGameState(roomId: roomId, state: state)
			} catch {
				await MainActor.run {
					print("[Network] sync error: \(error.localizedDescription)")
				}
			}
			
			await MainActor.run {
				
				guard let self else { return }
				self.isPushingNetworkState = false
				
				if let pending = self.pendingNetworkPush {
					self.pendingNetworkPush = nil
					self.pushNetworkGameStateIfNeeded(
						winnerId: pending.winnerId,
						force: pending.force,
						eventType: pending.eventType,
						eventMessage: pending.eventMessage
					)
				}
			}
		}
	}
	
	func applyNetworkGameState(_ state:CM_Game_State) {
		
		guard isNetworkMultiplayer else { return }
		guard state.revision > networkRevision else { return }
		
		let previousRollNumber = currentRollNumber
		let previousHasRolled = hasRolledThisTurn
		let previousEventId = networkEventId
		let previousCurrentId = networkPlayerIds[safe: currentPlayerIndex]
		let previousPlayerIndex = currentPlayerIndex
		let preservedPositions = Dictionary(uniqueKeysWithValues:
			diceViews.enumerated().compactMap { index, dice -> (Int, CGPoint)? in
				guard !dice.isLocked, let position = dice.originalPosition else { return nil }
				return (index, position)
			}
		)
		
		isApplyingRemoteState = true
		defer { isApplyingRemoteState = false }
		
		networkRevision = state.revision
		networkEventId = max(networkEventId, state.eventId)
		
		players = state.players.map { remote in
			let player = CM_Player()
			player.name = remote.name
			player.scores = remote.scores
			player.hasOpened = remote.hasOpened
			return player
		}
		networkPlayerIds = state.players.map(\.id)
		
		currentPlayerIndex = min(state.currentPlayerIndex, max(players.count - 1, 0))
		
		if currentPlayerIndex != previousPlayerIndex {
			lastShownCombination = nil
		}
		
		turnScore = state.turnScore
		turnScoreLabel.text = "\(turnScore)"
		accumulatedScore = state.accumulatedScore
		hasRolledThisTurn = state.hasRolledThisTurn
		currentRollNumber = state.currentRollNumber
		scoringDiceIndices = Set(state.scoringDiceIndices)
		isLastRound = state.isLastRound
		lastRoundTriggerPlayerIndex = state.lastRoundTriggerPlayerIndex
		playersWhoPlayedLastRound = Set(state.playersWhoPlayedLastRound)
		
		let isNewEvent = state.eventId > previousEventId
		let isNewRoll = state.hasRolledThisTurn && (state.currentRollNumber > previousRollNumber || (!previousHasRolled && state.hasRolledThisTurn))
		let becameMyTurn = previousPlayerIndex != currentPlayerIndex && isMyNetworkTurn()
		// L'auteur de l'action est le joueur courant avant apply (ou le courant du state si mid-tour)
		let actingPlayerId = previousCurrentId ?? state.players[safe: state.currentPlayerIndex]?.id
		let eventFromOther = actingPlayerId != nil && actingPlayerId != networkUserId
		
		// Synchroniser le décompte de tour (nil / nouveau tour = après le splash « À vous »)
		if state.winnerId != nil || state.status == "finished" || becameMyTurn {
			stopNetworkTurnTimer()
		} else if let endsAt = state.turnEndsAt {
			networkTurnEndsAt = endsAt
			startNetworkTurnTimer()
		} else {
			stopNetworkTurnTimer()
			updateValidateButton()
		}
		
		if diceViews.count != state.dice.count {
			setupDice()
			hasRolledThisTurn = state.hasRolledThisTurn
			currentRollNumber = state.currentRollNumber
			scoringDiceIndices = Set(state.scoringDiceIndices)
			accumulatedScore = state.accumulatedScore
		}
		
		updatePlayersDisplay()
		updateUIForCurrentPlayer()
		
		let presentYourTurnIfNeeded = { [weak self] in
			guard let self, becameMyTurn, state.winnerId == nil else { return }
			DispatchQueue.main.async {
				self.presentYourTurnSplashAndStartTimer()
			}
		}
		
		let presentRemoteFeedback = { [weak self] in
			guard let self else { return }
			
			var chainedYourTurn = false
			
			if isNewEvent {
				switch state.eventType {
				case "ballot" where eventFromOther:
					self.animateBallot()
				case "combination" where eventFromOther:
					if let message = state.eventMessage, !message.isEmpty {
						self.showCombinationTutorial(combinations: message.components(separatedBy: "\n"))
					}
				case "equality" where eventFromOther:
					self.presentRemoteEqualitySplash(eventMessage: state.eventMessage)
				case "lastRound" where eventFromOther:
					// Enchaîner « À vous » si le tour bascule dans le même apply
					self.showLastRoundTutorial {
						presentYourTurnIfNeeded()
					}
					chainedYourTurn = true
				case "timeout" where eventFromOther:
					self.presentTransientSplash(title: String(key: "network.game.timeout"), duration: 1.0) {
						presentYourTurnIfNeeded()
					}
					chainedYourTurn = true
				default:
					break
				}
			}
			
			if !chainedYourTurn {
				presentYourTurnIfNeeded()
			}
			
			if let winnerId = state.winnerId,
			   let index = self.networkPlayerIds.firstIndex(of: winnerId),
			   index < self.players.count {
				self.handleVictory(for: self.players[index])
			}
		}
		
		if isNewEvent, state.eventType == "playerLeft" {
			layoutNetworkDice(from: state, preservePositions: preservedPositions)
			updateRollHint()
			updateSelectedDicePlaceholder()
			pendingNetworkWinnerId = state.winnerId
			showPlayerLeftAlert(name: state.eventMessage) { [weak self] in
				self?.presentPendingNetworkVictoryIfNeeded()
			}
			return
		}
		
		if isNewRoll && eventFromOther {
			animateRemoteDiceRoll(from: state) {
				presentRemoteFeedback()
			}
		} else {
			layoutNetworkDice(from: state, preservePositions: !isNewRoll ? preservedPositions : [:])
			updateRollHint()
			updateSelectedDicePlaceholder()
			presentRemoteFeedback()
		}
	}
	
	private func animateRemoteDiceRoll(from state:CM_Game_State, completion:(()->Void)? = nil) {
		
		rollId += 1
		let currentRollId = rollId
		isRolling = true
		
		rollHintLabel.alpha = 0.0
		rollPlaceholderLabel.isHidden = true
		
		for dice in diceViews {
			selectedDiceStackView.removeArrangedSubview(dice)
			dice.removeFromSuperview()
			diceContainerView.addSubview(dice)
			dice.snp.removeConstraints()
			dice.translatesAutoresizingMaskIntoConstraints = true
		}
		
		view.layoutIfNeeded()
		
		var rollingDice:[(dice:CM_Dice, value:Int)] = []
		
		for (index, dieState) in state.dice.enumerated() where index < diceViews.count {
			
			let dice = diceViews[index]
			dice.isLocked = dieState.isLocked
			dice.lockedAtRoll = dieState.lockedAtRoll
			dice.transform = .identity
			dice.alpha = 1.0
			
			if dieState.isLocked {
				dice.value = dieState.value
				dice.isHidden = false
				dice.translatesAutoresizingMaskIntoConstraints = false
				selectedDiceStackView.addArrangedSubview(dice)
				dice.snp.remakeConstraints { make in
					make.width.height.equalTo(50)
				}
			} else {
				dice.isHidden = false
				rollingDice.append((dice, dieState.value))
			}
		}
		
		updateSelectedDicePlaceholder()
		
		guard !rollingDice.isEmpty else {
			isRolling = false
			updateRollHint()
			completion?()
			return
		}
		
		playRemoteRollFeedback(diceCount: rollingDice.count)
		
		let lockedPositions = diceViews
			.filter { $0.isLocked && $0.superview == diceContainerView }
			.compactMap { $0.originalPosition }
		let finalPositions = generateRandomPositions(count: rollingDice.count, avoiding: lockedPositions)
		
		let centerX = diceContainerView.bounds.midX - 25
		let centerY = diceContainerView.bounds.midY - 25
		
		for entry in rollingDice {
			positionDice(entry.dice, at: CGPoint(x: centerX, y: centerY))
		}
		
		let group = DispatchGroup()
		
		for (index, entry) in rollingDice.enumerated() {
			
			group.enter()
			
			let finalPosition = finalPositions[safe: index] ?? .zero
			entry.dice.originalPosition = finalPosition
			
			UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
				entry.dice.frame.origin = finalPosition
			}
			
			entry.dice.roll(to: entry.value, feedback: false) {
				group.leave()
			}
		}
		
		group.notify(queue: .main) { [weak self] in
			
			guard let self else {
				completion?()
				return
			}
			
			guard self.rollId == currentRollId else { return }
			
			self.isRolling = false
			self.updateRollHint()
			self.updateSelectedDicePlaceholder()
			completion?()
		}
	}
	
	private func layoutNetworkDice(from state:CM_Game_State, preservePositions:[Int:CGPoint] = [:]) {
		
		for dice in diceViews {
			selectedDiceStackView.removeArrangedSubview(dice)
			dice.removeFromSuperview()
			diceContainerView.addSubview(dice)
			dice.snp.removeConstraints()
			dice.translatesAutoresizingMaskIntoConstraints = true
		}
		
		view.layoutIfNeeded()
		
		let unlockedCount = state.dice.filter { !$0.isLocked }.count
		var positions:[CGPoint] = []
		
		if state.hasRolledThisTurn {
			var reused:[CGPoint] = []
			for index in state.dice.indices where !state.dice[index].isLocked {
				if let kept = preservePositions[index] {
					reused.append(kept)
				}
			}
			
			if reused.count == unlockedCount {
				positions = reused
			} else {
				positions = generateRandomPositions(count: unlockedCount, avoiding: reused)
				if !reused.isEmpty {
					positions = reused + Array(positions.prefix(max(0, unlockedCount - reused.count)))
				}
			}
		}
		
		var unlockedIndex = 0
		
		for (index, dieState) in state.dice.enumerated() where index < diceViews.count {
			
			let dice = diceViews[index]
			dice.value = dieState.value
			dice.isLocked = dieState.isLocked
			dice.lockedAtRoll = dieState.lockedAtRoll
			dice.transform = .identity
			dice.alpha = 1.0
			
			if dieState.isLocked {
				dice.isHidden = false
				dice.translatesAutoresizingMaskIntoConstraints = false
				selectedDiceStackView.addArrangedSubview(dice)
				dice.snp.remakeConstraints { make in
					make.width.height.equalTo(50)
				}
			} else if state.hasRolledThisTurn {
				dice.isHidden = false
				let position = positions[safe: unlockedIndex] ?? .zero
				unlockedIndex += 1
				dice.originalPosition = position
				dice.frame = CGRect(x: position.x, y: position.y, width: 50, height: 50)
			} else {
				dice.isHidden = true
				dice.originalPosition = nil
			}
		}
	}
	
	private func playRemoteRollFeedback(diceCount:Int) {
		
		let count = max(1, min(diceCount, 6))
		let key = CM_Audio.Sounds.RawValue(key: "Dice_\(count)")
		if let sound = CM_Audio.Sounds(rawValue: key) {
			CM_Audio.shared.playSound(sound)
		}
		CM_Feedback.shared.make(.On)
	}
	
	private func showPlayerLeftAlert(name:String?, completion:(()->Void)? = nil) {
		
		let alert = CM_Alert_ViewController()
		alert.title = String(key: "network.game.playerLeft.title")
		let playerName = name ?? "?"
		alert.add(String(format: String(key: "network.game.playerLeft.content"), playerName))
		alert.addDismissButton { _ in
			completion?()
		}
		alert.present()
	}
	
	private func presentPendingNetworkVictoryIfNeeded() {
		
		guard let winnerId = pendingNetworkWinnerId else { return }
		pendingNetworkWinnerId = nil
		
		guard let index = networkPlayerIds.firstIndex(of: winnerId),
			  index < players.count else { return }
		
		handleVictory(for: players[index])
	}
}

private extension Array {
	
	subscript(safe index:Int) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

// Helper class pour passer le joueur au gesture recognizer
private class PlayerTapGestureRecognizer: UITapGestureRecognizer {
	var player:CM_Player?
}
