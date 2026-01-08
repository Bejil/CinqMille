//
//  RR_Game_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class RR_Game_ViewController : RR_ViewController {
	
	private lazy var bannerView = RR_Ads.shared.presentBanner(Ads.Banner.Game, self)
	
	// MARK: - Mode de jeu
	
	/// Si true, tous les joueurs sont humains (pas d'IA)
	var isLocalMultiplayer: Bool = false
	
	/// Retourne true si le joueur actuel est un humain
	func isCurrentPlayerHuman() -> Bool {
		if isLocalMultiplayer {
			return true // En mode multijoueur local, tous les joueurs sont humains
		}
		return currentPlayerIndex == 0 // En mode solo, seul le premier joueur est humain
	}
	
	// MARK: - Propriétés de jeu
	
	var players:[RR_Player] = []
	var currentPlayerIndex:Int = 0
	var diceViews:[RR_Dice] = []
	var isRolling:Bool = false
	var turnScore:Int = 0
	var accumulatedScore:Int = 0 // Score accumulé des "bravo" précédents
	var hasRolledThisTurn:Bool = false
	var scoringDiceIndices:Set<Int> = []
	var currentRollNumber:Int = 0
	private var isAIPlaying:Bool = false // Indique si l'IA est en train de jouer
	private var aiTurnId:Int = 0 // Identifiant unique du tour IA pour annuler les appels asynchrones
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
	private lazy var selectedDicePlaceholderLabel:RR_Label = {
		
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(RR_Label(String(key: "game.selected.placeholder")))
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
	private lazy var rollHintLabel:RR_Label = {
		
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		$0.addLine(position: .top)
		$0.contentInsets.top = UI.Margins
		$0.isUserInteractionEnabled = true
		$0.addGestureRecognizer(UITapGestureRecognizer(block: { [weak self] _ in
			
			self?.handleDiceTap()
		}))
		return $0
		
	}(RR_Label(String(key: "game.roll.hint")))
	private lazy var rollPlaceholderLabel:RR_Label = {
		
		$0.font = Fonts.Content.Title.H4
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(RR_Label(String(key: "game.roll.hint")))
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
		
		let turnScoreTitleLabel:RR_Label = .init(String(key: "game.turn.score"))
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
	lazy var turnScoreLabel:RR_Label = {
		
		$0.font = Fonts.Content.Title.H2
		$0.textColor = Colors.Background.View
		$0.textAlignment = .center
		return $0
		
	}(RR_Label("0"))
	private lazy var validateButton:RR_Button = {
		
		$0.isEnabled = false
		$0.type = .secondary
		return $0
		
	}(RR_Button(String(key: "game.validate")) { [weak self] _ in
		
		self?.handleValidateOrSkip()
	})
	
	private func handleValidateOrSkip() {
		
		// Vérifier si c'est le tour d'une IA (pas le joueur humain index 0)
		if !isCurrentPlayerHuman() {
			// Mode "Passer" - simuler que l'IA a joué et passer au joueur suivant
			skipAITurn()
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
		isRolling = false
		
		// Arrêter toutes les animations des dés
		for dice in diceViews {
			dice.layer.removeAllAnimations()
		}
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = RR_Rules.shared
		
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
				
				// Appliquer la règle d'égalité
				if rules.equalityKnockback {
					applyEqualityKnockback(for: currentPlayer, newScore: currentPlayer.score)
				}
				
				// Vérifier victoire
				if currentPlayer.score >= rules.targetScore {
					updatePlayersDisplay()
					handleVictory(for: currentPlayer)
					return
				}
			}
		}
		
		// Réinitialiser l'état du tour
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
		
		let rules = RR_Rules.shared
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
		navigationItem.rightBarButtonItem = .init(customView: RR_Settings_Button())
		
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
		
		let alertController:RR_Alert_ViewController = .init()
		alertController.title = String(key: "game.close.alert.title")
		alertController.add(String(key: "game.close.alert.content"))
		let button = alertController.addButton(title: String(key: "game.close.alert.button")) { [weak self] _ in
			
			alertController.close { [weak self] in
				
				if !(self?.isLocalMultiplayer ?? true) {
					
					let currentPlayer = RR_Player.current
					currentPlayer.stats.abandonments += 1
					currentPlayer.save()
				}
				
				self?.dismiss()
			}
		}
		button.type = .delete
		alertController.addCancelButton()
		alertController.present()
	}
	
	public override func dismiss(_ completion: (() -> Void)? = nil) {
		
		RR_Player.current.resetGameState()
		
		super.dismiss {
			
			completion?()
			
			RR_Alert_ViewController.presentLoading({ alertController in
				
				RR_Ads.shared.presentInterstitial(Ads.FullScreen.Game.End, nil, {
				
					alertController?.close()
				})
			})
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
		
		let key = RR_Audio.Sounds.RawValue(key: "Dice_\(dices.count)")
		if let sound = RR_Audio.Sounds(rawValue: key) {
			RR_Audio.shared.playSound(sound)
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
			
			self.isRolling = false
			self.calculateTurnScore()
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
		var isBallot = (score == 0)
		
		// Vérifier si la règle exactScore est activée et si tous les dés scorants feraient dépasser
		if !isBallot && RR_Rules.shared.exactScore {
			let currentPlayer = players[currentPlayerIndex]
			var canSelectAnyDice = false
			
			// Vérifier chaque dé scorant individuellement
			for diceIndex in scoringDiceIndices {
				let dice = diceViews[diceIndex]
				let hypotheticalScore = calculateHypotheticalScore(selectingDice: dice)
				let potentialTotal = currentPlayer.score + hypotheticalScore
				
				if potentialTotal <= RR_Rules.shared.targetScore {
					canSelectAnyDice = true
					break
				}
			}
			
			// Si aucun dé ne peut être sélectionné sans dépasser, c'est un ballot forcé
			if !canSelectAnyDice {
				isBallot = true
			}
		}
		
		if isBallot {
			// Ballot - perd tous les points du tour
			RR_Audio.shared.playSound(.Error)
			RR_Feedback.shared.make(.Off)
			
			turnScore = 0
			turnScoreLabel.text = "0"
			
			animateBallot()
			
			// Après un ballot, réinitialiser pour le prochain tour
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
				self?.endTurn()
			}
		} else {
			
			// Mettre à jour l'affichage
			updateRollHint()
			
			// Afficher le tutoriel de sélection de dé si c'est le premier lancer et qu'il y a des dés scorants
			if isCurrentPlayerHuman() && !scoringDiceIndices.isEmpty {
				showDiceSelectionTutorial()
			}
		}
	}
	
	private func showDiceSelectionTutorial() {
		
		// Trouver le premier dé scorant pour le tutoriel
		guard let firstScoringIndex = scoringDiceIndices.first else { return }
		let scoringDice = diceViews[firstScoringIndex]
		
		let tutorial = RR_Tutorial_ViewController()
		tutorial.key = .diceSelectionTutorialShown
		tutorial.items = [
			RR_Tutorial_ViewController.Item(
				sourceView: scoringDice,
				title: String(key: "game.tutorial.selectDice.title"),
				subtitle: String(key: "game.tutorial.selectDice.subtitle"),
				button: String(key: "game.tutorial.selectDice.button"),
				closure: { [weak self] in
					guard let self = self else { return }
					
					// Sélectionner le dé
					scoringDice.isLocked = true
					scoringDice.lockedAtRoll = self.currentRollNumber
					
					RR_Audio.shared.playSound(.Tap)
					RR_Feedback.shared.make(.On)
					
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
				
				let tutorial2 = RR_Tutorial_ViewController()
				tutorial2.key = .selectedDiceTutorialShown
				tutorial2.items = [
					RR_Tutorial_ViewController.Item(
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
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = RR_Rules.shared
		
		// Ajouter le score du tour au tableau des scores
		currentPlayer.scores.append(turnScore)
		
		let newScore = currentPlayer.score
		
		// Appliquer la règle d'égalité si activée
		if rules.equalityKnockback {
			applyEqualityKnockback(for: currentPlayer, newScore: newScore)
		}
		
		// Marquer que le joueur a ouvert s'il ne l'avait pas encore fait
		if !currentPlayer.hasOpened {
			currentPlayer.hasOpened = true
		}
		
		// Mettre à jour l'affichage
		updatePlayersDisplay()
		
		// Vérifier si le joueur a gagné
		if newScore >= rules.targetScore {
			handleVictory(for: currentPlayer)
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
	private func applyEqualityKnockback(for currentPlayer:RR_Player, newScore:Int) {
		
		for player in players where player != currentPlayer {
			
			if player.score == newScore && !player.scores.isEmpty {
				// Le joueur perd son dernier score (retombe à son score précédent)
				let lastScore = player.scores.removeLast()
				
				// Afficher une notification de knockback
				showKnockbackNotification(player: player, lostPoints: lastScore)
			}
		}
	}
	
	private func showKnockbackNotification(player:RR_Player, lostPoints:Int) {
		
		// Vibration et son pour signaler le knockback
		RR_Audio.shared.playSound(.Error)
		RR_Feedback.shared.make(.On)
		
		// Animation visuelle sur le joueur affecté pourrait être ajoutée ici
		let viewController:RR_Tutorial_ViewController = .init()
		viewController.items = [
			RR_Tutorial_ViewController.Item(
				title: String(key: "game.equality.tutorial.title"),
				subtitle: player == players[currentPlayerIndex] ? String(key: "game.equality.tutorial.subtitle.currentPlayer") : player.name ?? "" + " " + String(key: "game.equality.tutorial.subtitle.player"),
				timeInterval: 1.5
			)
		]
		viewController.present()
	}
	
	private func handleVictory(for winner:RR_Player) {
		
		isAIPlaying = false
		
		// En mode multijoueur local, tout le monde est humain - pas de stats
		if isLocalMultiplayer {
			RR_Audio.shared.playSound(.Success)
			RR_Feedback.shared.make(.On)
		}
		// En mode solo, sauvegarder les stats du joueur
		else if winner == players.first {
			
			RR_Audio.shared.playSound(.Success)
			RR_Feedback.shared.make(.On)
			
			let currentPlayer = RR_Player.current
			currentPlayer.stats.wins += 1
			currentPlayer.save()
		}
		else {
			
			RR_Audio.shared.playSound(.Error)
			RR_Feedback.shared.make(.Off)
			
			let currentPlayer = RR_Player.current
			currentPlayer.stats.losses += 1
			currentPlayer.save()
		}
		
		// Afficher l'alerte de victoire
		let alert = RR_Alert_ViewController()
		alert.title = String(key: "game.victory.title")
		alert.add(String(format: String(key: "game.victory.content"), winner.name ?? "?", winner.score))
		alert.addButton(title: String(key: "game.victory.button")) { [weak self] _ in
			
			alert.close { [weak self] in
				
				RR_Confettis.stop()
				
				self?.dismiss()
			}
		}
		alert.present {
			RR_Confettis.start()
		}
	}
	
	private func canValidate() -> Bool {
		
		guard turnScore > 0 else { return false }
		
		let currentPlayer = players[currentPlayerIndex]
		let rules = RR_Rules.shared
		
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
		let rules = RR_Rules.shared
		let potentialScore = currentPlayer.score + turnScore
		
		return rules.exactScore && potentialScore > rules.targetScore
	}
	
	func updateValidateButton() {
		
		if isCurrentPlayerHuman() {
			// Tour du joueur humain - bouton "Valider"
			validateButton.isEnabled = canValidate()
		} else {
			// Tour de l'IA - bouton "Passer" toujours actif
			validateButton.isEnabled = true
		}
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
		
		// Passer au joueur suivant
		nextPlayer()
	}
	
	func nextPlayer() {
		
		// Réinitialiser l'état du tour
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
		updateValidateButton()
		updateUIForCurrentPlayer()
		updateRollHint()
		
		// Si c'est un adversaire (IA), jouer automatiquement
		if !isCurrentPlayerHuman() {
			playAI()
		} else {
			// C'est le tour du joueur humain - s'assurer que l'IA est arrêtée
			isAIPlaying = false
		}
		
		bannerView.refresh()
	}
	
	// MARK: - AI
	
	private func playAI() {
		
		// Incrémenter l'identifiant de tour pour invalider les anciens appels asynchrones
		aiTurnId += 1
		let currentTurnId = aiTurnId
		
		isAIPlaying = true
		
		// Délai avant le premier lancer de l'IA
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == currentTurnId else { return }
			self.aiRollDice(turnId: currentTurnId)
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
		let rules = RR_Rules.shared
		
		// Vérifier s'il y a des dés scorants à sélectionner
		let scoringDice = diceViews.enumerated().filter { scoringDiceIndices.contains($0.offset) && !$0.element.isLocked }
		
		guard !scoringDice.isEmpty else {
			// Ballot déjà géré dans calculateTurnScore
			return
		}
		
		// Filtrer les dés si on doit atteindre le score exact
		let diceToSelect: [RR_Dice]
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
	private func aiSelectDiceSequentially(diceToSelect:[RR_Dice], turnId:Int, completion:@escaping ()->Void) {
		
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
		
		RR_Audio.shared.playSound(.Tap)
		RR_Feedback.shared.make(.On)
		
		// Déplacer le dé vers la stackview des dés sélectionnés
		moveDiceToCorrectStackView(dice)
		
		// Délai avant le prochain dé
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			guard let self = self else { return }
			guard self.isAIPlaying && self.aiTurnId == turnId else { return }
			
			self.aiSelectDiceSequentially(diceToSelect: remainingDice, turnId: turnId, completion: completion)
		}
	}
	
	/// Filtre les dés que l'IA peut sélectionner sans dépasser le score cible
	private func aiFilterDiceForExactScore(scoringDice:[RR_Dice], player:RR_Player) -> [RR_Dice] {
		
		let rules = RR_Rules.shared
		let targetScore = rules.targetScore
		let currentPlayerScore = player.score
		let pointsRemaining = targetScore - currentPlayerScore
		
		// Si on est loin du score cible, on peut tout sélectionner
		if pointsRemaining > 2000 {
			return scoringDice
		}
		
		// Calculer le score actuel du tour (dés déjà verrouillés + accumulé)
		let currentTurnScore = accumulatedScore + calculateLockedDiceScore()
		let maxAllowedTurnScore = pointsRemaining
		
		// Si le score actuel du tour dépasse déjà, on ne peut rien sélectionner
		if currentTurnScore > maxAllowedTurnScore {
			return []
		}
		
		// Trier les dés par valeur de points (du plus petit au plus grand)
		// pour prioriser les sélections qui ne font pas dépasser
		let sortedDice = scoringDice.sorted { dice1, dice2 in
			let score1 = singleDiceScore(dice1.value)
			let score2 = singleDiceScore(dice2.value)
			return score1 < score2
		}
		
		var selectedDice: [RR_Dice] = []
		var simulatedScore = currentTurnScore
		
		// Essayer d'ajouter les dés un par un
		for dice in sortedDice {
			// Simuler l'ajout de ce dé
			let hypotheticalScore = calculateHypotheticalScoreForAI(adding: dice, toSelected: selectedDice)
			
			if currentPlayerScore + hypotheticalScore <= targetScore {
				selectedDice.append(dice)
				simulatedScore = hypotheticalScore
			}
			// Si on atteint exactement le score cible, on arrête
			if currentPlayerScore + simulatedScore == targetScore {
				break
			}
		}
		
		return selectedDice
	}
	
	/// Calcule le score hypothétique si l'IA sélectionne un dé supplémentaire
	private func calculateHypotheticalScoreForAI(adding newDice:RR_Dice, toSelected selected:[RR_Dice]) -> Int {
		
		var diceByRoll:[Int:[Int]] = [:]
		
		// Ajouter les dés déjà verrouillés
		for dice in diceViews where dice.isLocked {
			if let rollNumber = dice.lockedAtRoll {
				diceByRoll[rollNumber, default: []].append(dice.value)
			}
		}
		
		// Ajouter les dés déjà "sélectionnés" dans la simulation
		for dice in selected {
			diceByRoll[currentRollNumber, default: []].append(dice.value)
		}
		
		// Ajouter le nouveau dé
		diceByRoll[currentRollNumber, default: []].append(newDice.value)
		
		// Calculer le score
		var totalScore = 0
		for (_, values) in diceByRoll {
			let result = calculateCombinationScore(for: values)
			totalScore += result.score
		}
		
		return accumulatedScore + totalScore
	}
	
	/// Score d'un dé individuel (pour le tri)
	private func singleDiceScore(_ value:Int) -> Int {
		switch value {
		case 1: return 100
		case 5: return 50
		default: return 0
		}
	}
	
	/// Calcule le score des dés actuellement verrouillés
	private func calculateLockedDiceScore() -> Int {
		
		var diceByRoll:[Int:[Int]] = [:]
		
		for dice in diceViews where dice.isLocked {
			if let rollNumber = dice.lockedAtRoll {
				diceByRoll[rollNumber, default: []].append(dice.value)
			}
		}
		
		var totalScore = 0
		for (_, values) in diceByRoll {
			let result = calculateCombinationScore(for: values)
			totalScore += result.score
		}
		
		return totalScore
	}
	
	private func aiShouldValidate(currentPlayer:RR_Player, rules:RR_Rules) -> Bool {
		
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
		
		let rules = RR_Rules.shared
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
		
		let viewController:RR_Tutorial_ViewController = .init()
		viewController.items = [
			RR_Tutorial_ViewController.Item(
				title: String(key: "game.ballot"),
				timeInterval: 0.5
			)
		]
		viewController.present()
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		super.viewWillAppear(animated)
		
		RR_Alert_ViewController.presentLoading({ [weak self] alertController in
			
			RR_Ads.shared.presentInterstitial(Ads.FullScreen.Game.Start, nil, { [weak self] in
				
				alertController?.close { [weak self] in
					
					let alertViewController:RR_Alert_ViewController = .init()
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
			})
		})
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
		RR_Player.current.resetGameState()
		
		players.append(RR_Player.current)
		
		for i in 1...numberOfOpponents {
			
			let player:RR_Player = .init()
			player.name = String(key: "game.opponents.default.name") + " \(i)"
			players.append(player)
		}
		
		currentPlayerIndex = 0
		turnScore = 0
		turnScoreLabel.text = "0"
		
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
		
		let tutorial = RR_Tutorial_ViewController()
		tutorial.key = .gameTutorialShown
		tutorial.items = [
			RR_Tutorial_ViewController.Item(
				sourceView: playersStackView.arrangedSubviews.first,
				title: String(key: "game.tutorial.players.title"),
				subtitle: String(key: "game.tutorial.players.subtitle"),
				button: String(key: "game.tutorial.players.button")
			),
			RR_Tutorial_ViewController.Item(
				sourceView: scoreLabelsStackView,
				title: String(key: "game.tutorial.score.title"),
				subtitle: String(key: "game.tutorial.score.subtitle"),
				button: String(key: "game.tutorial.score.button")
			),
			RR_Tutorial_ViewController.Item(
				sourceView: validateButton,
				title: String(key: "game.tutorial.validate.title"),
				subtitle: String(key: "game.tutorial.validate.subtitle"),
				button: String(key: "game.tutorial.validate.button")
			)
		]
		tutorial.present()
	}
	
	func updateUIForCurrentPlayer() {
		
		let isHumanTurn = isCurrentPlayerHuman()
		
		if isHumanTurn {
			// Tour du joueur humain
			validateButton.title = String(key: "game.validate")
			validateButton.type = .secondary
			validateButton.isEnabled = canValidate()
			diceContainerView.isUserInteractionEnabled = true
		} else {
			// Tour de l'IA - afficher le bouton "Passer"
			validateButton.title = String(key: "game.skip")
			validateButton.type = .tertiary
			validateButton.isEnabled = true
			diceContainerView.isUserInteractionEnabled = false
		}
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
		
		let diceCount = RR_Rules.shared.diceCount
		
		for _ in 0..<diceCount {
			
			let dice = RR_Dice()
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
		guard let dice = gesture.view as? RR_Dice else { return }
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
			if RR_Rules.shared.exactScore {
				let hypotheticalScore = calculateHypotheticalScore(selectingDice: dice)
				let potentialTotal = players[currentPlayerIndex].score + hypotheticalScore
				
				if potentialTotal > RR_Rules.shared.targetScore {
					showDiceSelectionError(dice)
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
		
		RR_Audio.shared.playSound(.Tap)
		RR_Feedback.shared.make(.On)
		
		// Animation de déplacement du dé
		moveDiceToCorrectStackView(dice)
		
		// Recalculer le score total des dés sélectionnés
		updateSelectedDiceScore()
		
		// Mettre à jour le hint
		updateRollHint()
	}
	
	/// Déplace un dé vers la bonne stackview (sélectionnés ou à lancer)
	private func moveDiceToCorrectStackView(_ dice:RR_Dice) {
		
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
	private func positionDice(_ dice:RR_Dice, at position:CGPoint) {
		
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
		
		// Afficher un tutoriel si une combinaison est détectée
		if !detectedCombinations.isEmpty {
			showCombinationTutorial(combinations: detectedCombinations, completion: completion)
		} else {
			completion?()
		}
		
		// Vérifier victoire instantanée
		if hasInstantWin {
			handleInstantWin()
		}
	}
	
	/// Calcule le score hypothétique si on sélectionnait un dé supplémentaire
	private func calculateHypotheticalScore(selectingDice:RR_Dice) -> Int {
		
		// Simuler la sélection du dé
		var diceByRoll:[Int:[Int]] = [:]
		
		// Ajouter les dés déjà verrouillés
		for dice in diceViews where dice.isLocked {
			if let rollNumber = dice.lockedAtRoll {
				diceByRoll[rollNumber, default: []].append(dice.value)
			}
		}
		
		// Ajouter le dé qu'on veut sélectionner
		diceByRoll[currentRollNumber, default: []].append(selectingDice.value)
		
		// Calculer le score pour chaque groupe
		var hypotheticalScore = 0
		
		for (_, values) in diceByRoll {
			let result = calculateCombinationScore(for: values)
			hypotheticalScore += result.score
		}
		
		// Ajouter le score accumulé des "bravo" précédents
		return accumulatedScore + hypotheticalScore
	}
	
	/// Affiche une erreur de sélection de dé (shake + son)
	private func showDiceSelectionError(_ dice:RR_Dice) {
		
		RR_Feedback.shared.make(.Error)
		
		// Animation de refus
		let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
		animation.timingFunction = CAMediaTimingFunction(name: .linear)
		animation.duration = 0.3
		animation.values = [-5, 5, -5, 5, 0]
		dice.layer.add(animation, forKey: "shake")
	}
	
	/// Détecte le nom de la combinaison formée par les dés
	private func detectCombinationName(for values:[Int]) -> String? {
		
		guard values.count >= 3 else { return nil }
		
		let rules = RR_Rules.shared
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
	
	private func showCombinationTutorial(combinations:[String], completion:(()->Void)? = nil) {
		
		// Ne montrer qu'une seule fois par combinaison
		let combinationKey = combinations.joined(separator: "-")
		guard combinationKey != lastShownCombination else {
			completion?()
			return
		}
		lastShownCombination = combinationKey
		
		let combinationText = combinations.joined(separator: "\n")
		
		let viewController:RR_Tutorial_ViewController = .init()
		viewController.items = [
			RR_Tutorial_ViewController.Item(
				title: combinationText,
				timeInterval: 1.5
			)
		]
		viewController.completion = completion
		viewController.present()
	}
	
	private func handleInstantWin() {
		
		handleVictory(for: players[currentPlayerIndex])
	}
	
	private func updateRollHint() {
		
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
			
			let playerStackView = createPlayerStackView(player: player, isCurrentPlayer: index == currentPlayerIndex)
			playersStackView.addArrangedSubview(playerStackView)
		}
	}
	
	private func createPlayerStackView(player:RR_Player, isCurrentPlayer:Bool) -> UIStackView {
		
		let nameLabel:RR_Label = .init(player.name)
		nameLabel.font = Fonts.Content.Title.H4
		nameLabel.textColor = isCurrentPlayer ? Colors.Primary : Colors.Content.Title
		nameLabel.textAlignment = .center
		nameLabel.numberOfLines = 1
		nameLabel.adjustsFontSizeToFitWidth = true
		nameLabel.minimumScaleFactor = 0.5
		
		let scoreLabel:RR_Label = .init("\(player.score)")
		scoreLabel.font = Fonts.Content.Title.H4.withSize(Fonts.Content.Title.H4.pointSize - 4)
		scoreLabel.textColor = Colors.Content.Text
		scoreLabel.textAlignment = .center
		
		let stackView:UIStackView = .init(arrangedSubviews: [nameLabel, scoreLabel])
		stackView.axis = .vertical
		stackView.spacing = UI.Margins/2
		stackView.alignment = .center
		stackView.backgroundColor = isCurrentPlayer ? Colors.Primary.withAlphaComponent(0.2) : .clear
		stackView.layer.cornerRadius = UI.CornerRadius
		stackView.layer.borderWidth = isCurrentPlayer ? 2 : 0
		stackView.layer.borderColor = Colors.Primary.cgColor
		stackView.isLayoutMarginsRelativeArrangement = true
		stackView.layoutMargins = .init(UI.Margins)
		
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
	
	private func showPlayerScores(player:RR_Player) {
		
		let alertViewController:RR_Alert_ViewController = .init()
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
}

// Helper class pour passer le joueur au gesture recognizer
private class PlayerTapGestureRecognizer: UITapGestureRecognizer {
	var player:RR_Player?
}
